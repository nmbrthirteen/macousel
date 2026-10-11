import Foundation

struct ManagerComponents {
  let state: TilingState
  let presenter: LayoutPresenter
  let reconciler: WindowReconciler
  let focus: FocusDriver
  let release: WindowRelease
  let router: CommandRouter
  let appShortcuts: AppShortcutLauncher
  let indicator: StripPositionIndicator
  let floating: FloatingWindowKeeper
  let systemFocus: SystemFocusHandler

  init(store: PreferencesStore, ports: ManagerPorts, defaults: UserDefaults) {
    let state = TilingState(store: store, environment: ports.environment, pointer: ports.pointer)
    let overlays = OverlayPresenter(
      state: state, source: ports.source, store: store, environment: ports.environment,
      host: ports.overlays)
    let admissionFrames = AdmissionFrames()
    let indicator = StripPositionIndicator(state: state)
    let clock = ports.clock
    let presenter = LayoutPresenter(
      state: state, source: ports.source, environment: ports.environment, store: store,
      placer: ports.placer, clock: clock, overlays: overlays,
      indicator: indicator, admissionFrames: admissionFrames)
    let restorer = WindowRestorer(
      defaults: defaults, bootSession: ports.environment.bootSessionIdentifier)
    let focus = FocusDriver(
      state: state, source: ports.source, store: store, pointer: ports.pointer, now: { clock.now })
    let scratchpad = Scratchpad(
      state: state, source: ports.source, placer: ports.placer, focus: focus)
    let floating = FloatingWindowKeeper(
      state: state, source: ports.source, environment: ports.environment, store: store,
      clock: clock, scratchpad: scratchpad, frames: FloatingFrameCache(probe: ports.probe))
    focus.onActivated = { window in floating.focusRequested(window) }
    focus.needsRaise = { window in !floating.canFocusWithoutRaising(window) }
    let reconciler = WindowReconciler(
      state: state, source: ports.source, environment: ports.environment, store: store,
      probe: ports.probe, restorer: restorer, sessions: SessionStore(defaults: defaults),
      admissionFrames: admissionFrames, scratchpad: scratchpad, recents: focus.recents,
      now: { clock.now })
    let overview = OverviewController(
      state: state, source: ports.source, host: ports.overlays,
      titles: { reconciler.capturedTitles },
      springResponse: { store.preferences.animationSpeed.springResponse })
    self.state = state
    self.indicator = indicator
    self.floating = floating
    systemFocus = SystemFocusHandler(
      state: state, presenter: presenter, focus: focus, floating: floating)
    self.presenter = presenter
    self.reconciler = reconciler
    self.focus = focus
    release = WindowRelease(
      state: state, source: ports.source, environment: ports.environment, restorer: restorer,
      presenter: presenter, scratchpad: scratchpad)
    let router = CommandRouter(
      state: state, source: ports.source, presenter: presenter, focus: focus,
      reconciler: reconciler, scratchpad: scratchpad, overview: overview)
    self.router = router
    appShortcuts = AppShortcutLauncher(
      state: state, source: ports.source, environment: ports.environment,
      recents: focus.recents, router: router)
  }
}
