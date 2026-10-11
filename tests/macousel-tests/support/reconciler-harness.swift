import CoreGraphics
import StripCore
import WindowSystem

@testable import Macousel

@MainActor
struct ReconcilerHarness {
  let environment: FakeDesktopEnvironment
  let source: FakeWindowSource
  let state: TilingState
  let reconciler: WindowReconciler
  let scratchpad: Scratchpad

  init(suite: IsolatedDefaults) {
    let store = PreferencesStore(defaults: suite.defaults)
    store.preferences.restoresSession = false
    environment = FakeDesktopEnvironment(displays: [.fake()])
    source = FakeWindowSource(environment: environment)
    let pointer = FakePointerDevice()
    state = TilingState(store: store, environment: environment, pointer: pointer)
    let focus = FocusDriver(
      state: state, source: source, store: store, pointer: pointer,
      now: { ContinuousClock.now })
    let scratchpad = Scratchpad(
      state: state, source: source, placer: FakeFramePlacer(), focus: focus)
    self.scratchpad = scratchpad
    reconciler = WindowReconciler(
      state: state, source: source, environment: environment, store: store,
      restorer: WindowRestorer(defaults: suite.defaults, bootSession: "boot-1"),
      sessions: SessionStore(defaults: suite.defaults), admissionFrames: AdmissionFrames(),
      scratchpad: scratchpad,
      recents: focus.recents, now: { ContinuousClock.now })
  }

  func key(space: UInt64 = 1) -> Workspace.Key {
    Workspace.Key(displayUUID: Display.fake().uuid, space: space)
  }

  func strip(space: UInt64 = 1) -> Strip {
    state.workspaces[key(space: space)]?.strip ?? Strip()
  }

  func order(space: UInt64 = 1) -> [CGWindowID] {
    strip(space: space).windows.map(\.rawValue)
  }

  @discardableResult
  func open(_ id: CGWindowID, atX x: CGFloat) -> FakeWindow {
    let window = FakeWindow(
      id: id, app: .editor, title: "Window \(id)",
      frame: CGRect(x: x, y: 100, width: 400, height: 300))
    source.add(window, activating: false)
    return window
  }
}
