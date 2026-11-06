import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct PaneruFloatingTests {
  private let harness = EngineHarness()
  private let environment = FakeDesktopEnvironment(displays: [.fake()])
  private let shortcuts = FakeShortcutRegistry()

  private static func tile(_ id: Int32, x: Int, focused: Bool = false) -> EngineWindow {
    EngineWindow(
      windowId: id, bundleId: "app.\(id)", appName: "App \(id)", focused: focused, displayId: 1,
      frame: EngineWindow.Frame(x: x, y: 25, width: 500, height: 700))
  }

  private static func floater(_ id: Int32, x: Int, focused: Bool = false) -> EngineWindow {
    EngineWindow(
      windowId: id, bundleId: "app.\(id)", appName: "App \(id)", focused: focused,
      floating: true, displayId: 1,
      frame: EngineWindow.Frame(x: x, y: 100, width: 300, height: 200))
  }

  private func running(
    configure: (inout Preferences) -> Void = { _ in }
  ) async throws -> PaneruEngine {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    configure(&store.preferences)
    let engine = harness.makeEngine(store: store, environment: environment, shortcuts: shortcuts)
    engine.start()
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })
    return engine
  }

  private func adopt(_ windows: [EngineWindow], in engine: PaneruEngine) async {
    let snapshot = EngineFixtures.snapshot(of: windows)
    harness.commands.snapshot = snapshot
    harness.events.onEvent?(.windowsChanged(workspace: 1, active: EngineActive()))
    #expect(await harness.eventually { engine.position == snapshot.stripPosition })
    await settle()
  }

  private func settle() async {
    for _ in 0..<50 { await Task.yield() }
  }

  @Test func focusingATiledWindowRaisesTheFloatingWindowsOverItWithoutFocusingThem() async throws {
    let engine = try await running()

    await adopt(
      [Self.tile(1, x: 0, focused: true), Self.tile(2, x: 500), Self.floater(10, x: 600)],
      in: engine)
    await adopt(
      [Self.tile(1, x: 0), Self.tile(2, x: 500, focused: true), Self.floater(10, x: 600)],
      in: engine)
    harness.clock.advance(by: FloatingWindowKeeper.raiseDelay)

    #expect(harness.windows.raised.last == [10])
    #expect(harness.windows.focused.isEmpty)
    #expect(!harness.commands.sent.contains(["window", "raise", "floating"]))
  }

  @Test func turningThePreferenceOffLeavesFloatingWindowsWhereTheyAre() async throws {
    let engine = try await running { $0.keepsFloatingWindowsOnTop = false }

    await adopt(
      [Self.tile(1, x: 0), Self.tile(2, x: 500, focused: true), Self.floater(10, x: 600)],
      in: engine)
    harness.clock.advance(by: FloatingWindowKeeper.raiseDelay)

    #expect(harness.windows.raised.isEmpty)
  }

  @Test func focusPreviousReturnsToTheTiledWindowFocusedBefore() async throws {
    let engine = try await running()
    await adopt([Self.tile(1, x: 0, focused: true), Self.tile(2, x: 500)], in: engine)
    await adopt([Self.tile(1, x: 0), Self.tile(2, x: 500, focused: true)], in: engine)

    engine.perform(.focusPrevious)

    #expect(await harness.eventually { harness.commands.sent.contains(["window", "focus", "1"]) })
  }

  @Test func focusPreviousReturnsToAFloatingWindow() async throws {
    let engine = try await running()
    await adopt([Self.tile(1, x: 0), Self.floater(10, x: 600, focused: true)], in: engine)
    await adopt([Self.tile(1, x: 0, focused: true), Self.floater(10, x: 600)], in: engine)

    engine.perform(.focusPrevious)

    #expect(harness.windows.focused == [10])
  }

  @Test func focusPreviousWithoutHistoryDoesNothing() async throws {
    let engine = try await running()
    await adopt([Self.tile(1, x: 0, focused: true), Self.tile(2, x: 500)], in: engine)

    engine.perform(.focusPrevious)
    await settle()

    #expect(!harness.commands.sent.contains { $0.starts(with: ["window", "focus"]) })
    #expect(harness.windows.focused.isEmpty)
  }

  @Test func bringingBackMovesOnlyTheFloatingWindowsThatAreMostlyOffScreen() async throws {
    let engine = try await running()
    await adopt(
      [Self.tile(1, x: 0, focused: true), Self.floater(10, x: 4000), Self.floater(11, x: 600)],
      in: engine)

    engine.perform(.bringBackFloatingWindows)

    #expect(await harness.eventually { !harness.windows.moved.isEmpty })
    #expect(harness.windows.moved == [10: CGRect(x: 700, y: 100, width: 300, height: 200)])
  }

  @Test func theOverviewShowsFloatingWindowsAndChoosingOneFocusesIt() async throws {
    let engine = try await running()
    await adopt(
      [Self.tile(1, x: 0, focused: true), Self.tile(2, x: 500), Self.floater(10, x: 600)],
      in: engine)

    engine.perform(.toggleOverview)
    #expect(harness.overlays.overview?.snapshot.floating.map(\.window) == [WindowID(10)])
    harness.overlays.onOverviewSelect?(WindowID(10))

    #expect(harness.windows.focused == [10])
    #expect(harness.overlays.overview == nil)
    #expect(!harness.commands.sent.contains { $0.starts(with: ["window", "focus"]) })
  }

  @Test func theFloatingLayerShortcutGoesToTheEngine() throws {
    let lines = EngineConfigBindings(shortcuts: Action.defaultShortcuts).lines

    #expect(lines.contains(#"window_togglefloatlayer = "alt + ctrl - grave""#))
    #expect(!lines.contains { $0.contains("backslash") })
  }
}
