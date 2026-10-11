import AppKit
import StripCore
import WindowSystem
import os

private let logger = Logger(subsystem: "dev.macousel.app", category: "window-manager")

@Observable
final class WindowManager {
  enum Status: Sendable {
    case needsPermission, running, paused
  }

  private static let permissionPollInterval = Duration.seconds(1)
  private static let synchronizationDelays: [Duration] = [.milliseconds(60), .milliseconds(340)]

  private(set) var status: Status = .needsPermission
  private(set) var displays: [Display] = []

  private let store: PreferencesStore
  private let tracker: WindowTracker
  private let environment = EnvironmentObserver()
  private let hotkeys = HotkeyCenter()
  private let state: TilingState
  private let presenter: LayoutPresenter
  private let restorer: WindowRestorer
  private let reconciler: WindowReconciler
  private let router: CommandRouter
  private let drag: DragInteraction
  private let scrolling: ScrollInteraction
  private let hover: FocusFollowsPointer

  @ObservationIgnored private var appliedPreferences: Preferences?
  @ObservationIgnored private var synchronization: Task<Void, Never>?
  @ObservationIgnored private var permissionPoll: Task<Void, Never>?

  init(store: PreferencesStore) {
    let tracker = WindowTracker()
    let state = TilingState(store: store)
    let overlays = OverlayPresenter(state: state, tracker: tracker, store: store)
    let presenter = LayoutPresenter(
      state: state, tracker: tracker, store: store, overlays: overlays)
    let restorer = WindowRestorer()
    let reconciler = WindowReconciler(
      state: state, tracker: tracker, store: store, restorer: restorer)
    let focus = FocusDriver(state: state, tracker: tracker, store: store)

    self.store = store
    self.tracker = tracker
    self.state = state
    self.presenter = presenter
    self.restorer = restorer
    self.reconciler = reconciler
    router = CommandRouter(
      state: state, tracker: tracker, presenter: presenter, focus: focus, reconciler: reconciler)
    drag = DragInteraction(state: state, tracker: tracker, presenter: presenter)
    scrolling = ScrollInteraction(state: state, presenter: presenter, focus: focus, store: store)
    hover = FocusFollowsPointer(state: state, presenter: presenter, focus: focus, store: store)
  }

  func start() {
    displays = Display.all()
    guard !AccessibilityPermission.isGranted else {
      begin()
      return
    }
    logger.info("Waiting for Accessibility access")
    AccessibilityPermission.requestWithPrompt()
    permissionPoll = Task {
      while !AccessibilityPermission.isGranted {
        try? await Task.sleep(for: Self.permissionPollInterval)
        if Task.isCancelled { return }
      }
      begin()
    }
  }

  func perform(_ action: Action) {
    switch (action, status) {
    case (_, .needsPermission): break
    case (.togglePaused, .running): pause()
    case (.togglePaused, .paused): resume()
    case (_, .running): router.perform(action)
    case (_, .paused): break
    }
  }

  func shutdown() {
    permissionPoll?.cancel()
    synchronization?.cancel()
    guard status != .needsPermission else { return }
    if status == .running {
      reconciler.saveSession()
      releaseWindows()
    }
    restorer.forgetAll()
    hotkeys.removeAll()
    stopInteractions()
    tracker.stop()
    environment.stop()
  }

  private func begin() {
    status = .running
    logger.info("Accessibility access granted, tiling started")
    connectEvents()
    tracker.start()
    environment.start()
    drag.start()
    applyInputs()
    synchronize()
  }

  private func connectEvents() {
    tracker.onEvent = { [weak self] event in self?.handle(event) }
    environment.onSpaceChanged = { [weak self] in self?.scheduleSynchronization() }
    environment.onDisplaysChanged = { [weak self] in
      self?.presenter.invalidateAll()
      self?.scheduleSynchronization()
    }
    presenter.overlays.onTabSelected = { [weak self] window in self?.router.select(window) }
    hover.isSuppressed = { [weak self] in
      self.map { $0.drag.isActive || $0.scrolling.isActive } ?? true
    }
    store.onChange = { [weak self] in self?.preferencesChanged() }
  }

  private func pause() {
    status = .paused
    logger.info("Tiling paused")
    synchronization?.cancel()
    releaseWindows()
    applyInputs()
  }

  private func resume() {
    status = .running
    logger.info("Tiling resumed")
    applyInputs()
    synchronize()
  }

  private func releaseWindows() {
    presenter.halt()
    let managed = state.workspaces.values.flatMap(\.strip.windows)
    restorer.restore(managed.compactMap { tracker.windows[$0.rawValue] }, on: state.displays)
  }

  private func stopInteractions() {
    drag.stop()
    scrolling.stop()
    hover.stop()
  }

  private func applyInputs() {
    let isTiling = status == .running
    hotkeys.setBindings(activeBindings())
    scrolling.configure(isTiling: isTiling)
    hover.configure(isTiling: isTiling)
  }

  private func activeBindings() -> [Hotkey: () -> Void] {
    guard !store.isRecordingShortcut else { return [:] }
    var bindings: [Hotkey: () -> Void] = [:]
    for (action, keys) in store.preferences.shortcuts
    where status == .running || action == .togglePaused {
      for key in keys {
        bindings[key] = { [weak self] in self?.perform(action) }
      }
    }
    return bindings
  }

  private func preferencesChanged() {
    guard status != .needsPermission else { return }
    applyInputs()
    guard status == .running, store.preferences != appliedPreferences else { return }
    appliedPreferences = store.preferences
    presenter.invalidateAll()
    presenter.overlays.restackDim()
    synchronize()
  }

  private func scheduleSynchronization() {
    synchronization?.cancel()
    synchronization = Task {
      for delay in Self.synchronizationDelays {
        try? await Task.sleep(for: delay)
        if Task.isCancelled { return }
        synchronize()
      }
    }
  }

  private func synchronize() {
    guard status == .running else { return }
    reconciler.reconcile()
    if displays != state.displays { displays = state.displays }
    presenter.retain(only: Set(tracker.windows.keys))
    presenter.overlays.refreshTitles()
    presenter.relayout()
  }

  private func handle(_ event: WindowEvent) {
    guard status == .running else { return }
    switch event {
    case .created, .destroyed, .minimized, .restored, .appHidden, .appShown:
      scheduleSynchronization()
    case .focused(let window):
      focusChanged(to: WindowID(window))
    case .moved(let window), .resized(let window):
      drag.windowChanged(window)
    }
  }

  private func focusChanged(to window: WindowID) {
    presenter.overlays.restackDim()
    let key = state.activeKey(containing: window)
    state.focusedKey = key
    guard let key, state.workspaces[key]?.strip.focusedWindow != window else {
      presenter.render()
      return
    }
    state.workspaces[key]?.strip.focus(window)
    state.scrollToFocus(key)
    presenter.relayout()
  }
}
