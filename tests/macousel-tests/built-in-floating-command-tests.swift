import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct BuiltInFloatingCommandTests {
  @Test func switchingToFloatingWindowsFocusesTheFrontFloatingWindow() throws {
    let scenario = try FloatingScenario()

    scenario.fixture.manager.perform(.switchToFloatingWindows)

    #expect(scenario.fixture.source.focusedWindow()?.id == 10)
  }

  @Test func switchingAgainReturnsToTheStrip() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.manager.perform(.switchToFloatingWindows)

    scenario.fixture.manager.perform(.switchToFloatingWindows)

    #expect(scenario.fixture.source.focusedWindow()?.id == 1)
  }

  @Test func bringingBackMovesAFloatingWindowOffScreenOntoTheDisplay() throws {
    let scenario = try FloatingScenario()
    let visible = scenario.fixture.display.visibleFrame
    scenario.fixture.source.userMoved(
      scenario.floater, to: CGRect(x: visible.maxX + 2000, y: visible.minY, width: 300, height: 200)
    )

    scenario.fixture.manager.perform(.bringBackFloatingWindows)

    #expect(
      scenario.floater.frame
        == CGRect(x: visible.maxX - 300, y: visible.minY, width: 300, height: 200))
  }

  @Test func bringingBackLeavesAFloatingWindowOnScreenAlone() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.bringBackFloatingWindows)

    #expect(scenario.floater.frame == scenario.coveringFrame)
  }

  @Test func theOverviewShowsTheFloatingWindowAndChoosingItFocusesIt() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.toggleOverview)
    let shown = try #require(scenario.fixture.overlays.overview?.snapshot)
    #expect(shown.floating.map(\.window) == [WindowID(10)])
    #expect(shown.floating.first?.frame == scenario.coveringFrame)
    scenario.fixture.overlays.onOverviewSelect?(WindowID(10))

    #expect(scenario.fixture.source.focusedWindow()?.id == 10)
  }

  @Test func focusPreviousGoesBackToTheWindowFocusedBefore() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.manager.perform(.focusRight)
    #expect(scenario.fixture.source.focusedWindow()?.id == 3)

    scenario.fixture.manager.perform(.focusPrevious)
    #expect(scenario.fixture.source.focusedWindow()?.id == 2)

    scenario.fixture.manager.perform(.focusPrevious)
    #expect(scenario.fixture.source.focusedWindow()?.id == 3)
  }
}
