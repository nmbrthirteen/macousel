import CoreGraphics
import Foundation
import StripCore
import WindowSystem

@testable import Macousel

@MainActor
final class ControllerFixture {
  private static let patience = Duration.seconds(60)

  let suite: IsolatedDefaults
  let store: PreferencesStore
  let environment: FakeDesktopEnvironment
  let source: FakeWindowSource
  let probe: FakeWindowProbe
  let sequence = EventSequence()
  let placer = FakeFramePlacer()
  let clock = ManualClock()
  let pointer = FakePointerDevice()
  let shortcuts = FakeShortcutRegistry()
  let gestures = FakeGestureInput()
  let overlays = FakeOverlayHost()
  let crashRecovery = FakeCrashRecovery()
  let manager: WindowManager
  private var hasQuit = false

  init(
    displays: [Display] = [.fake()], suite: IsolatedDefaults? = nil,
    bootSession: String = "boot-1", preferences: (inout Preferences) -> Void = { _ in }
  ) throws {
    let suite = try suite ?? IsolatedDefaults()
    let store = PreferencesStore(defaults: suite.defaults)
    store.preferences.animationSpeed = .off
    preferences(&store.preferences)
    let environment = FakeDesktopEnvironment(displays: displays)
    environment.bootSessionIdentifier = bootSession
    let source = FakeWindowSource(environment: environment)
    self.suite = suite
    self.store = store
    self.environment = environment
    self.source = source
    probe = FakeWindowProbe(source: source)
    placer.sequence = sequence
    pointer.serverBoundsProvider = { source.fakeWindow($0)?.serverFrame }
    manager = WindowManager(
      store: store,
      ports: ManagerPorts(
        source: source, probe: probe, placer: placer, clock: clock, environment: environment,
        pointer: pointer, shortcuts: shortcuts, gestures: gestures, overlays: overlays,
        crashRecovery: crashRecovery),
      defaults: suite.defaults,
      polling: AccessibilityMonitor.Intervals(
        whileWaiting: .milliseconds(10), whileWatching: .milliseconds(10)))
    try FixtureRegistry.enroll(self)
  }

  func tearDown() {
    guard !hasQuit else { return }
    hasQuit = true
    if manager.status == .paused { manager.perform(.togglePaused) }
    manager.shutdown()
  }

  var display: Display { environment.displays[0] }

  var config: LayoutConfig { store.preferences.layout }

  func launch() {
    manager.start()
  }

  func quit() {
    hasQuit = true
    manager.shutdown()
  }

  @discardableResult
  func open(
    _ id: CGWindowID, app: FakeApp = .editor, title: String? = nil, atX x: CGFloat = 0,
    activating: Bool = false
  ) -> FakeWindow {
    let window = FakeWindow(
      id: id, app: app, title: title ?? "Window \(id)",
      frame: CGRect(x: x, y: 100, width: 400, height: 300))
    window.sequence = sequence
    source.add(window, activating: activating)
    return window
  }

  func openRow(_ count: CGWindowID) -> [FakeWindow] {
    (1...count).map { open($0, atX: CGFloat($0) * 200, activating: $0 == 1) }
  }

  func frames(of windows: [FakeWindow]) -> [CGWindowID: CGRect] {
    windows.reduce(into: [:]) { frames, window in frames[window.id] = window.frame }
  }

  func becomes(_ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + Self.patience
    while !condition() {
      if ContinuousClock.now > deadline { return false }
      try? await Task.sleep(for: .milliseconds(5))
    }
    return true
  }

  func windowShowingFocusBorder(among windows: [FakeWindow]) -> FakeWindow? {
    guard let border = overlays.focusBorder else { return nil }
    return windows.first { $0.frame == border.frame }
  }
}
