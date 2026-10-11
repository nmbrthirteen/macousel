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

  private(set) var status: Status = .needsPermission
  private(set) var displays: [Display] = []

  private let store: PreferencesStore
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let state: TilingState
  private let presenter: LayoutPresenter
  private let release: WindowRelease
  private let accessibility: AccessibilityMonitor
  private let reconciler: WindowReconciler
  private let focus: FocusDriver
  private let router: CommandRouter
  private let interactions: ManagerInteractions
  private let inputs: InputBindings
  private let crashRecovery: any CrashRecovery

  @ObservationIgnored private var appliedPreferences: Preferences?
  @ObservationIgnored private let synchronization = SynchronizationScheduler()
  @ObservationIgnored private var hasLostAccess = false
  @ObservationIgnored private var restoresArrivingWindows = false

  convenience init(store: PreferencesStore) {
    self.init(store: store, ports: .system(), defaults: .standard, polling: .standard)
  }

  init(
    store: PreferencesStore, ports: ManagerPorts, defaults: UserDefaults,
    polling: AccessibilityMonitor.Intervals = .standard
  ) {
    let parts = ManagerComponents(store: store, ports: ports, defaults: defaults)
    self.store = store
    self.source = ports.source
    self.environment = ports.environment
    state = parts.state
    presenter = parts.presenter
    reconciler = parts.reconciler
    focus = parts.focus
    release = parts.release
    router = parts.router
    accessibility = AccessibilityMonitor(environment: ports.environment, intervals: polling)
    let interactions = ManagerInteractions(
      state: parts.state, source: ports.source, presenter: parts.presenter, focus: parts.focus,
      store: store, ports: ports)
    self.interactions = interactions
    inputs = InputBindings(
      store: store, shortcuts: ports.shortcuts, interactions: interactions,
      appShortcuts: parts.appShortcuts)
    crashRecovery = ports.crashRecovery
  }

  func start() {
    displays = environment.displays
    if environment.isAccessibilityGranted { begin() } else { awaitAccessibility() }
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
    accessibility.stop()
    if status == .running {
      reconciler.saveSession()
      release.releaseEverything()
    }
    if status != .needsPermission && environment.isAccessibilityGranted { release.forgetSaved() }
    stopSystem()
  }

  private func stopSystem() {
    router.closeOverview()
    synchronization.cancel()
    reconciler.cancelPending()
    focus.stop()
    crashRecovery.disarm()
    inputs.release()
    source.stop()
    environment.stopObserving()
  }

  private func awaitAccessibility() {
    logger.info("Waiting for Accessibility access")
    environment.requestAccessibilityAccess()
    accessibility.waitForGrant { [weak self] in self?.begin() }
  }

  private func accessibilityLost() {
    logger.error("Accessibility access was lost, tiling stopped")
    status = .needsPermission
    hasLostAccess = true
    restoresArrivingWindows = false
    presenter.halt()
    stopSystem()
    awaitAccessibility()
  }

  private func begin() {
    connectEvents()
    source.start()
    environment.startObserving()
    interactions.start()
    accessibility.watchForLoss { [weak self] in self?.accessibilityLost() }
    if hasLostAccess || crashRecovery.isRecoveringFromCrash {
      release.restoreEverythingSaved()
    }
    hasLostAccess = false
    if crashRecovery.isRecoveringFromCrash {
      pauseForRecovery()
      return
    }
    status = .running
    logger.info("Accessibility access granted, tiling started")
    crashRecovery.arm()
    applyInputs()
    synchronize()
  }

  private func pauseForRecovery() {
    status = .paused
    restoresArrivingWindows = true
    logger.info("Recovering windows after a crash, tiling paused")
    applyInputs()
  }

  private func connectEvents() {
    synchronization.onSynchronize = { [weak self] in self?.synchronize() }
    source.onEvent = { [weak self] event in self?.handle(event) }
    environment.onSpaceChanged = { [weak self] in
      self?.router.closeOverview()
      self?.synchronization.schedule()
    }
    environment.onDisplaysChanged = { [weak self] in
      self?.router.closeOverview()
      self?.presenter.invalidateAll()
      self?.synchronization.schedule()
    }
    focus.onUnconfirmedFocus = { [weak self] window in
      guard self?.status == .running else { return }
      self?.focusChanged(to: window)
    }
    presenter.overlays.onTabSelected = { [weak self] window in self?.router.select(window) }
    store.onChange = { [weak self] in self?.preferencesChanged() }
  }

  private func pause() {
    status = .paused
    logger.info("Tiling paused")
    router.closeOverview()
    crashRecovery.disarm()
    synchronization.cancel()
    reconciler.cancelPending()
    release.releaseEverything()
    applyInputs()
  }

  private func resume() {
    status = .running
    restoresArrivingWindows = false
    logger.info("Tiling resumed")
    crashRecovery.arm()
    applyInputs()
    synchronize()
  }

  private func applyInputs() {
    inputs.apply(isTiling: status == .running) { [weak self] action in self?.perform(action) }
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

  private func synchronize() {
    guard status == .running else { return }
    reconciler.reconcile { [weak self] in self?.finishSynchronizing() }
  }

  private func finishSynchronizing() {
    guard status == .running else { return }
    interactions.displaysSynchronized()
    if displays != state.displays { displays = state.displays }
    presenter.retain(only: Set(source.windows.keys))
    presenter.overlays.refreshTitles(using: reconciler.probedTitles)
    presenter.relayout()
  }

  private func handle(_ event: WindowSourceEvent) {
    if restoresArrivingWindows, case .created(let window) = event {
      release.restoreSaved(window)
    }
    guard status == .running else { return }
    switch event {
    case .created:
      synchronization.schedule(delays: SynchronizationScheduler.creationDelays)
    case .destroyed, .minimized, .restored, .appHidden, .appShown:
      synchronization.schedule()
    case .focused(let window):
      focusChanged(to: WindowID(window))
    case .moved(let window):
      interactions.windowMoved(window)
    case .resized(let window):
      reconciler.invalidateFullScreen(window)
      interactions.windowResized(window)
    }
  }

  private func focusChanged(to window: WindowID) {
    guard !focus.isEchoOfEarlierActivation(window) else { return }
    focus.observed(window)
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
