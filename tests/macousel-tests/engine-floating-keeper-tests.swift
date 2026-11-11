import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineFloatingKeeperTests {
  private let clock = ManualClock()
  private let windows = FakeEngineWindowControl()

  private static func tile(_ id: Int32, x: Int, focused: Bool = false) -> EngineWindow {
    EngineWindow(
      windowId: id, focused: focused, displayId: 1,
      frame: EngineWindow.Frame(x: x, y: 0, width: 500, height: 600))
  }

  private static func floater(_ id: Int32, x: Int, y: Int = 100, width: Int = 200) -> EngineWindow {
    EngineWindow(
      windowId: id, floating: true, displayId: 1,
      frame: EngineWindow.Frame(x: x, y: y, width: width, height: 200))
  }

  private static func snapshot(focusing focused: Int32, floaters: [EngineWindow]) -> EngineSnapshot
  {
    EngineFixtures.snapshot(
      of: [tile(1, x: 0, focused: focused == 1), tile(2, x: 500, focused: focused == 2)]
        + floaters)
  }

  private func makeKeeper(keepsOnTop: Bool = true) throws -> EngineFloatingKeeper {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    store.preferences.keepsFloatingWindowsOnTop = keepsOnTop
    return EngineFloatingKeeper(
      store: store, clock: clock, windows: windows, stackingOrder: { [30, 10, 20] })
  }

  @Test func coversOnlyTheFloatingWindowsOverTheFocusedWindow() {
    let snapshot = Self.snapshot(
      focusing: 2, floaters: [Self.floater(10, x: 100), Self.floater(20, x: 600)])

    #expect(EngineFloatingKeeper.covering(2, in: snapshot, frontToBack: []) == [20])
  }

  @Test func aFloatingWindowOfTheFocusedAppIsLeftAlone() {
    var player = Self.floater(10, x: 600)
    player.bundleId = "test.browser"
    var page = Self.tile(2, x: 500, focused: true)
    page.bundleId = "test.browser"
    let snapshot = EngineFixtures.snapshot(
      of: [Self.tile(1, x: 0), page, player, Self.floater(20, x: 650)])

    #expect(EngineFloatingKeeper.covering(2, in: snapshot, frontToBack: []) == [20])
  }

  @Test func aFloatingWindowThatOnlyGrazesTheFocusedWindowIsLeftAlone() {
    let grazing = Int(FloatingWindowKeeper.minimumOverlap / 2)
    let snapshot = Self.snapshot(focusing: 2, floaters: [Self.floater(10, x: 300 + grazing)])

    #expect(EngineFloatingKeeper.covering(2, in: snapshot, frontToBack: []).isEmpty)
  }

  @Test func ordersTheCoveringWindowsFrontToBack() {
    let snapshot = Self.snapshot(
      focusing: 2,
      floaters: [Self.floater(10, x: 600), Self.floater(20, x: 650), Self.floater(30, x: 700)])

    #expect(
      EngineFloatingKeeper.covering(2, in: snapshot, frontToBack: [30, 10, 20]) == [30, 10, 20])
  }

  @Test func aWindowWithoutAFrameCoversNothing() {
    let snapshot = EngineFixtures.snapshot(
      of: [EngineWindow(windowId: 1, focused: true, displayId: 1), Self.floater(10, x: 0)])

    #expect(EngineFloatingKeeper.covering(1, in: snapshot, frontToBack: []).isEmpty)
  }

  @Test func raisesTheCoveringWindowsBackToFrontAfterTheDelay() throws {
    let keeper = try makeKeeper()
    keeper.adopted(
      Self.snapshot(focusing: 2, floaters: [Self.floater(10, x: 600), Self.floater(30, x: 700)]))

    clock.advance(by: FloatingWindowKeeper.raiseDelay - .milliseconds(1))
    #expect(windows.raised.isEmpty)
    clock.advance(by: .milliseconds(1))

    #expect(windows.raised == [[10, 30]])
  }

  @Test func theSameFocusAgainRaisesNothingNew() throws {
    let keeper = try makeKeeper()
    let snapshot = Self.snapshot(focusing: 2, floaters: [Self.floater(10, x: 600)])
    keeper.adopted(snapshot)
    clock.advance(by: FloatingWindowKeeper.raiseDelay)

    keeper.adopted(snapshot)
    clock.advance(by: FloatingWindowKeeper.raiseDelay)

    #expect(windows.raised == [[10]])
  }

  @Test func aNewerFocusReplacesThePendingRaise() throws {
    let keeper = try makeKeeper()
    let floaters = [Self.floater(10, x: 100), Self.floater(20, x: 600)]
    keeper.adopted(Self.snapshot(focusing: 1, floaters: floaters))
    clock.advance(by: FloatingWindowKeeper.raiseDelay / 2)

    keeper.adopted(Self.snapshot(focusing: 2, floaters: floaters))
    clock.advance(by: FloatingWindowKeeper.raiseDelay)

    #expect(windows.raised == [[20]])
  }

  @Test func staysStillWhenThePreferenceIsOff() throws {
    let keeper = try makeKeeper(keepsOnTop: false)
    keeper.adopted(Self.snapshot(focusing: 2, floaters: [Self.floater(10, x: 600)]))
    clock.advance(by: FloatingWindowKeeper.raiseDelay)

    #expect(windows.raised.isEmpty)
  }

  @Test func staysStillWhileSuppressed() throws {
    let keeper = try makeKeeper()
    keeper.isSuppressed = { true }
    keeper.adopted(Self.snapshot(focusing: 2, floaters: [Self.floater(10, x: 600)]))
    clock.advance(by: FloatingWindowKeeper.raiseDelay)

    #expect(windows.raised.isEmpty)
  }
}
