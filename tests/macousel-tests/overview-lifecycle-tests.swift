import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct OverviewLifecycleTests {
  private func openedOverview() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)
    return (fixture, row)
  }

  @Test func anotherActionClosesTheOverviewAndStillRuns() throws {
    let (fixture, row) = try openedOverview()
    #expect(fixture.overlays.overview != nil)

    fixture.manager.perform(.focusRight)

    #expect(fixture.overlays.overview == nil)
    #expect(row[1].focusCount == 1)
  }

  @Test func shortcutPressClosesTheOverviewAndStillRuns() throws {
    let (fixture, row) = try openedOverview()
    let hotkey = try #require(Action.defaultShortcuts[.focusRight]?.first)

    fixture.shortcuts.trigger(hotkey)

    #expect(fixture.overlays.overview == nil)
    #expect(row[1].focusCount == 1)
  }

  @Test func scratchpadActionsCloseTheOverview() throws {
    let (fixture, _) = try openedOverview()

    fixture.manager.perform(.sendToScratchpad)

    #expect(fixture.overlays.overview == nil)
  }

  @Test func spaceChangeClosesTheOverview() throws {
    let (fixture, _) = try openedOverview()

    fixture.environment.switchSpace(of: fixture.display, to: 2, showing: [])

    #expect(fixture.overlays.overview == nil)
  }

  @Test func displayChangeClosesTheOverview() throws {
    let (fixture, _) = try openedOverview()

    fixture.environment.onDisplaysChanged?()

    #expect(fixture.overlays.overview == nil)
  }

  @Test func pausingClosesTheOverview() throws {
    let (fixture, _) = try openedOverview()

    fixture.manager.perform(.togglePaused)

    #expect(fixture.overlays.overview == nil)
  }

  @Test func quittingClosesTheOverview() throws {
    let (fixture, _) = try openedOverview()

    fixture.quit()

    #expect(fixture.overlays.overview == nil)
  }

  @Test func losingAccessibilityClosesTheOverview() async throws {
    let (fixture, _) = try openedOverview()

    fixture.environment.isAccessibilityGranted = false

    #expect(await fixture.becomes { fixture.overlays.overview == nil })
    #expect(fixture.manager.status == .needsPermission)
  }

  @Test func overviewDoesNotOpenWhilePaused() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(2)
    fixture.launch()
    fixture.manager.perform(.togglePaused)

    fixture.manager.perform(.toggleOverview)

    #expect(fixture.overlays.overview == nil)
  }
}
