import AppKit
import ApplicationServices
import os

private let logger = Logger(subsystem: "dev.macousel.app", category: "window-tracker")

private nonisolated func observerCallback(
  _ observer: AXObserver, _ element: AXUIElement, _ notification: CFString,
  _ refcon: UnsafeMutableRawPointer?
) {
  guard let refcon else { return }
  let address = Int(bitPattern: refcon)
  let name = notification as String
  nonisolated(unsafe) let observer = observer
  nonisolated(unsafe) let element = element
  MainActor.assumeIsolated {
    guard let pointer = UnsafeMutableRawPointer(bitPattern: address) else { return }
    Unmanaged<WindowTracker>.fromOpaque(pointer).takeUnretainedValue().handle(
      observer: observer, element: element, notification: name)
  }
}

public final class WindowTracker {
  static let messagingTimeout: Float = 0.25

  private static let attachAttempts = 5
  private static let attachDelay = Duration.milliseconds(200)

  private static let applicationNotifications = [
    kAXWindowCreatedNotification, kAXFocusedWindowChangedNotification,
    kAXMainWindowChangedNotification, kAXApplicationHiddenNotification,
    kAXApplicationShownNotification,
  ]
  private static let windowNotifications = [
    kAXUIElementDestroyedNotification, kAXWindowMovedNotification,
    kAXWindowResizedNotification, kAXWindowMiniaturizedNotification,
    kAXWindowDeminiaturizedNotification,
  ]

  private struct AppEntry {
    let app: NSRunningApplication
    let element: AXUIElement
    let observer: AXObserver
  }

  public var onEvent: ((WindowEvent) -> Void)?
  public private(set) var windows: [CGWindowID: ManagedWindow] = [:]

  private var apps: [pid_t: AppEntry] = [:]
  private var pidsByObserver: [ObjectIdentifier: pid_t] = [:]
  private var attachTasks: [pid_t: Task<Void, Never>] = [:]
  private var idsByElement: [ElementKey: CGWindowID] = [:]
  private var workspaceTokens: [NSObjectProtocol] = []

  public init() {}

  public func start() {
    guard workspaceTokens.isEmpty else { return }
    workspaceTokens = [
      observeWorkspace(NSWorkspace.didLaunchApplicationNotification) { [weak self] pid in
        self?.appLaunched(pid: pid)
      },
      observeWorkspace(NSWorkspace.didTerminateApplicationNotification) { [weak self] pid in
        self?.appTerminated(pid: pid)
      },
      observeWorkspace(NSWorkspace.didActivateApplicationNotification) { [weak self] pid in
        self?.appActivated(pid: pid)
      },
    ]

    for app in NSWorkspace.shared.runningApplications {
      attach(app, announce: false)
    }
  }

  public func stop() {
    for token in workspaceTokens { NSWorkspace.shared.notificationCenter.removeObserver(token) }
    workspaceTokens = []
    for task in attachTasks.values { task.cancel() }
    attachTasks = [:]
    for pid in Array(apps.keys) { detach(pid: pid) }
    windows = [:]
    idsByElement = [:]
  }

  public func focusedWindow() -> ManagedWindow? {
    guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
      let entry = apps[pid],
      let element = entry.element.elementAttribute(kAXFocusedWindowAttribute),
      let id = element.windowID
    else { return nil }
    return windows[id]
  }

  private func observeWorkspace(
    _ name: Notification.Name, _ handler: @escaping @MainActor (pid_t) -> Void
  ) -> NSObjectProtocol {
    NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) {
      note in
      guard
        let pid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?
          .processIdentifier
      else { return }
      MainActor.assumeIsolated { handler(pid) }
    }
  }

  private func appLaunched(pid: pid_t) {
    guard let app = NSRunningApplication(processIdentifier: pid) else { return }
    attach(app, announce: true)
  }

  private func appTerminated(pid: pid_t) {
    attachTasks.removeValue(forKey: pid)?.cancel()
    let ids = windows.values.filter { $0.pid == pid }.map(\.id)
    detach(pid: pid)
    for id in ids { onEvent?(.destroyed(id)) }
  }

  private func appActivated(pid: pid_t) {
    guard let entry = apps[pid],
      let element = entry.element.elementAttribute(kAXFocusedWindowAttribute),
      let id = trackedID(of: element, in: entry, announce: true)
    else { return }
    onEvent?(.focused(id))
  }

  private func attach(_ app: NSRunningApplication, announce: Bool) {
    let pid = app.processIdentifier
    guard app.activationPolicy == .regular, pid != getpid(), !app.isTerminated,
      apps[pid] == nil, attachTasks[pid] == nil
    else { return }

    if tryAttach(app, announce: announce) { return }
    attachTasks[pid] = Task {
      for _ in 1..<Self.attachAttempts {
        try? await Task.sleep(for: Self.attachDelay)
        if Task.isCancelled { return }
        if tryAttach(app, announce: announce) {
          attachTasks[pid] = nil
          return
        }
      }
      attachTasks[pid] = nil
      logger.error("Gave up observing \(app.localizedName ?? "pid \(pid)", privacy: .public)")
    }
  }

  private func tryAttach(_ app: NSRunningApplication, announce: Bool) -> Bool {
    let pid = app.processIdentifier
    let element = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(element, Self.messagingTimeout)

    var created: AXObserver?
    guard AXObserverCreate(pid, observerCallback, &created) == .success, let observer = created
    else { return false }

    let refcon = Unmanaged.passUnretained(self).toOpaque()
    for name in Self.applicationNotifications {
      let result = AXObserverAddNotification(observer, element, name as CFString, refcon)
      if result == .cannotComplete && name == kAXWindowCreatedNotification { return false }
    }
    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)

    let entry = AppEntry(app: app, element: element, observer: observer)
    apps[pid] = entry
    pidsByObserver[ObjectIdentifier(observer)] = pid
    for windowElement in element.elementsAttribute(kAXWindowsAttribute) {
      _ = trackedID(of: windowElement, in: entry, announce: announce)
    }
    return true
  }

  private func detach(pid: pid_t) {
    if let entry = apps.removeValue(forKey: pid) {
      pidsByObserver[ObjectIdentifier(entry.observer)] = nil
      CFRunLoopRemoveSource(
        CFRunLoopGetMain(), AXObserverGetRunLoopSource(entry.observer), .commonModes)
    }
    for window in windows.values where window.pid == pid {
      idsByElement.removeValue(forKey: ElementKey(element: window.element))
      windows.removeValue(forKey: window.id)
    }
  }

  private func trackedID(of element: AXUIElement, in entry: AppEntry, announce: Bool)
    -> CGWindowID?
  {
    if let id = idsByElement[ElementKey(element: element)] { return id }
    guard element.attribute(kAXRoleAttribute) == kAXWindowRole, let id = element.windowID
    else { return nil }
    if windows[id] != nil {
      idsByElement[ElementKey(element: element)] = id
      return id
    }

    let refcon = Unmanaged.passUnretained(self).toOpaque()
    for name in Self.windowNotifications {
      AXObserverAddNotification(entry.observer, element, name as CFString, refcon)
    }
    let window = ManagedWindow(
      id: id, element: element, applicationElement: entry.element, app: entry.app)
    windows[id] = window
    idsByElement[ElementKey(element: element)] = id
    if announce { onEvent?(.created(window)) }
    return id
  }

  fileprivate func handle(observer: AXObserver, element: AXUIElement, notification: String) {
    guard let pid = pidsByObserver[ObjectIdentifier(observer)], let entry = apps[pid]
    else { return }

    switch notification {
    case kAXWindowCreatedNotification:
      _ = trackedID(of: element, in: entry, announce: true)
    case kAXFocusedWindowChangedNotification, kAXMainWindowChangedNotification:
      guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
        let id = trackedID(of: element, in: entry, announce: true)
      else { return }
      onEvent?(.focused(id))
    case kAXApplicationHiddenNotification:
      onEvent?(.appHidden(pid))
    case kAXApplicationShownNotification:
      onEvent?(.appShown(pid))
    case kAXUIElementDestroyedNotification:
      guard let id = idsByElement.removeValue(forKey: ElementKey(element: element)) else { return }
      windows.removeValue(forKey: id)
      onEvent?(.destroyed(id))
    default:
      guard let id = idsByElement[ElementKey(element: element)] else { return }
      switch notification {
      case kAXWindowMovedNotification: onEvent?(.moved(id))
      case kAXWindowResizedNotification: onEvent?(.resized(id))
      case kAXWindowMiniaturizedNotification: onEvent?(.minimized(id))
      case kAXWindowDeminiaturizedNotification: onEvent?(.restored(id))
      default: break
      }
    }
  }
}
