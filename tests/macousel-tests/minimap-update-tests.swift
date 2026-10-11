import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct MinimapUpdateTests {
  private func launched(
    windows: CGWindowID = 6, speed: AnimationSpeed = .fast
  ) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.animationSpeed = speed }
    let row = fixture.openRow(windows)
    fixture.launch()
    while fixture.clock.isRunning { fixture.clock.tick() }
    return (fixture, row)
  }

  @Test func aCommandUpdatesTheMinimapAsAnimated() throws {
    let (fixture, _) = try launched()
    fixture.manager.perform(.focusRight)
    #expect(fixture.overlays.minimapUpdate == .animated)
    #expect(fixture.overlays.minimap?.columns.filter(\.isFocused).count == 1)
  }

  @Test func aSwipeUpdatesTheMinimapAsImmediate() throws {
    let (fixture, _) = try launched()
    fixture.manager.perform(.focusRight)
    fixture.gestures.onSwipe?(-0.05, .began)
    #expect(fixture.overlays.minimapUpdate == .immediate)
  }

  @Test func aScrollUpdatesTheMinimapAsImmediate() throws {
    let (fixture, _) = try launched()
    fixture.manager.perform(.focusRight)
    fixture.gestures.onScroll?(-50, .began)
    #expect(fixture.overlays.minimapUpdate == .immediate)
  }

  @Test func theSnapshotCarriesTheAnimationResponseOfTheSpeedSetting() throws {
    let (fixture, _) = try launched(speed: .relaxed)
    fixture.manager.perform(.focusRight)
    #expect(fixture.overlays.minimap?.animationResponse == 0.42)
  }

  @Test func theSnapshotHasNoResponseWhenAnimationIsOff() throws {
    let (fixture, _) = try launched(speed: .off)
    fixture.manager.perform(.focusRight)
    #expect(fixture.overlays.minimap?.animationResponse == nil)
  }

  @Test func theSnapshotHasNoResponseUnderReduceMotion() throws {
    let (fixture, _) = try launched()
    fixture.environment.reducesMotion = true
    fixture.manager.perform(.focusRight)
    #expect(fixture.overlays.minimap?.animationResponse == nil)
  }

  @Test func theSnapshotHasNoResponseInLowPowerMode() throws {
    let (fixture, _) = try launched()
    fixture.environment.isLowPowerModeEnabled = true
    fixture.manager.perform(.focusRight)
    #expect(fixture.overlays.minimap?.animationResponse == nil)
  }

  @Test func rowsCarryTheWindowIdentityAndBundleIdentifier() throws {
    let (fixture, _) = try launched()
    fixture.manager.perform(.focusRight)
    let columns = try #require(fixture.overlays.minimap?.columns)
    #expect(columns.map { $0.rows.map(\.window) } == (1...6).map { [WindowID(UInt32($0))] })
    #expect(columns.allSatisfy { $0.rows.allSatisfy { $0.bundleIdentifier == "test.editor" } })
  }

  @Test func aStackedColumnListsEveryWindowAsARow() throws {
    let (fixture, _) = try launched()
    fixture.manager.perform(.stackLeft)
    let first = try #require(fixture.overlays.minimap?.columns.first)
    #expect(first.rows.map(\.window) == [WindowID(2), WindowID(1)])
    #expect(!first.isTabbed)
  }

  @Test func aTabbedColumnIsMarkedAndKeepsItsActiveRow() throws {
    let (fixture, _) = try launched()
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleTabbed)
    let first = try #require(fixture.overlays.minimap?.columns.first)
    #expect(first.isTabbed)
    #expect(first.rows.count == 2)
    #expect(first.activeRow == 1)
  }
}
