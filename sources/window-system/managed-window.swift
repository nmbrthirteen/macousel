import AppKit
import ApplicationServices
import os

public final class ManagedWindow {
  private static let focusQueue = DispatchQueue(
    label: "dev.macousel.focus", qos: .userInteractive)
  private static let focusRequests = FocusRequests()
  private nonisolated static let logger = Logger(subsystem: "dev.macousel.app", category: "focus")
  private static let windowServerSettleDelay = 0.15

  public let id: CGWindowID
  public let pid: pid_t
  public let bundleIdentifier: String?
  public let appName: String

  let element: AXUIElement
  private let applicationElement: AXUIElement

  init(
    id: CGWindowID, element: AXUIElement, applicationElement: AXUIElement,
    app: NSRunningApplication
  ) {
    self.id = id
    self.element = element
    self.applicationElement = applicationElement
    self.pid = app.processIdentifier
    self.bundleIdentifier = app.bundleIdentifier
    self.appName = app.localizedName ?? ""
    AXUIElementSetMessagingTimeout(element, WindowTracker.messagingTimeout)
  }

  public var title: String {
    element.windowTitle()
  }

  public var frame: CGRect? {
    element.windowFrame()
  }

  public func setFrame(_ frame: CGRect) {
    let enhanced: Bool = applicationElement.attribute("AXEnhancedUserInterface") ?? false
    if enhanced { applicationElement.set(bool: false, for: "AXEnhancedUserInterface") }
    defer {
      if enhanced { applicationElement.set(bool: true, for: "AXEnhancedUserInterface") }
    }

    element.set(size: frame.size, for: kAXSizeAttribute)
    element.set(point: frame.origin, for: kAXPositionAttribute)
    element.set(size: frame.size, for: kAXSizeAttribute)
  }

  public func setPosition(_ origin: CGPoint) {
    element.set(point: origin, for: kAXPositionAttribute)
  }

  public var isMinimized: Bool {
    element.attribute(kAXMinimizedAttribute) ?? false
  }

  public func focus(raising: Bool = true) {
    let target = ThreadSafeAXElement(element: element)
    let pid = pid
    let id = id
    let requests = Self.focusRequests
    let settleDelay = Self.windowServerSettleDelay
    let request = requests.begin()
    Self.focusQueue.async {
      guard requests.isLatest(request) else { return }
      let usedWindowServer =
        request.usesWindowServer
        && (raising
          ? WindowServerFocus.shared.bringToFront(id, of: pid)
          : WindowServerFocus.shared.focusWithoutRaising(
            id, of: pid, replacing: FocusedWindowReader.current()))
      Self.logger.info(
        "focus request: window \(id, privacy: .public) raising \(raising, privacy: .public) window server \(usedWindowServer, privacy: .public)"
      )
      if raising || !usedWindowServer {
        AXUIElementPerformAction(target.element, kAXRaiseAction as CFString)
      }
      target.element.set(bool: true, for: kAXMainAttribute)
      DispatchQueue.main.asyncAfter(
        deadline: .now() + (usedWindowServer ? settleDelay : 0)
      ) {
        guard requests.isLatest(request) else { return }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier != pid else {
          if usedWindowServer { requests.recordHit() }
          return
        }
        if usedWindowServer { requests.recordMiss() }
        Self.logger.info(
          "focus verification failed: window \(id, privacy: .public), activating the app")
        NSRunningApplication(processIdentifier: pid)?.activate()
      }
    }
  }

  public func raise() {
    let target = ThreadSafeAXElement(element: element)
    Self.focusQueue.async {
      AXUIElementPerformAction(target.element, kAXRaiseAction as CFString)
    }
  }

  public func close() {
    guard let button = element.elementAttribute(kAXCloseButtonAttribute) else { return }
    AXUIElementPerformAction(button, kAXPressAction as CFString)
  }
}
