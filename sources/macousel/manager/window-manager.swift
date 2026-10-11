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
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let shortcuts: any ShortcutRegistry
  private let state: TilingState
  private let presenter: LayoutPresenter
  private let restorer: WindowRestorer
  private let reconciler: WindowReconciler
  private let focus: FocusDriver
  private let router: CommandRouter
  private let drag: DragInteraction
  private let scrolling: ScrollInteraction
  private let hover: FocusFollowsPointer

  @ObservationIgnored private var appliedPreferences: Preferences?
  @ObservationIgnored private var synchronization: Task<Void, Never>?
  @ObservationIgnored private var permissionPoll: Task<Void, Never>?

  convenience init(store: PreferencesStore) {
    self.init(store: store, ports: .system(), defaults: .standard)
  }

  init(store: PreferencesStore, ports: ManagerPorts, defaults: UserDefaults) {
    let state = TilingState(
      store: store, environment: ports.environment, pointer: ports.pointer)
    let overlays = OverlayPresenter(
      state: state, source: ports.source, store: store, host: ports.overlays)
    let presenter = LayoutPresenter(
      state: state, source: ports.source, environment: ports.environment, store: store,
      placer: ports.placer, clock: ports.clock, overlays: overlays)
    let restorer = WindowRestorer(defaults: defaults)
    let reconciler = WindowReconciler(
      state: state, source: ports.source, environment: ports.environment, store: store,
      restorer: restorer, sessions: SessionStore(defaults: defaults))
    focus = FocusDriver(
      state: state, source: ports.source, store: store, pointer: ports.pointer)

    self.store = store
    self.source = ports.source
    self.environment = ports.environment
    self.shortcuts = ports.shortcuts
    self.state = state
    self.presenter = presenter
    self.restorer = restorer
    self.reconciler = reconciler
    router = CommandRouter(
      state: state, source: ports.source, presenter: presenter, focus: focus,
      reconciler: reconciler)
    drag = DragInteraction(
      state: state, source: ports.source, presenter: presenter, pointer: ports.pointer)
    scrolling = ScrollInteraction(
      state: state, presenter: presenter, focus: focus, store: store, gestures: ports.gestures)
    hover = FocusFollowsPointer(
      state: state, presenter: presenter, focus: focus, store: store, pointer: ports.pointer)
  }

  func start() {
    displays = environment.displays
    guard !environment.isAccessibilityGranted else {
      begin()
      return
    }
    logger.info("Waiting for Accessibility access")
    environment.requestAccessibilityAccess()
    permissionPoll = Task {
      while !environment.isAccessibilityGranted {
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
    shortcuts.removeAll()
    stopInteractions()
    source.stop()
    environment.stopObserving()
  }

  private func begin() {
    status = .running
    logger.info("Accessibility access granted, tiling started")
    connectEvents()
    source.start()
    environment.startObserving()
    drag.start()
    applyInputs()
    synchronize()
  }

  private func connectEvents() {
    source.onEvent = { [weak self] event in self?.handle(event) }
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
    restorer.restore(managed.compactMap { source.window($0.rawValue) }, on: state.displays)
  }

  private func stopInteractions() {
    drag.stop()
    scrolling.stop()
    hover.stop()
  }

  private func applyInputs() {
    let isTiling = status == .running
    shortcuts.setBindings(activeBindings())
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
    presenter.retain(only: Set(source.windows.keys))
    presenter.overlays.refreshTitles()
    presenter.relayout()
  }

  private func handle(_ event: WindowSourceEvent) {
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
    guard !focus.isEchoOfEarlierActivation(window) else { return }
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
