import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct FloatingWindowSuppressionTests {
  @Test func nothingIsRaisedWhileTilingIsPaused() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.manager.perform(.togglePaused)
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func nothingIsRaisedWhileTheOverviewIsOpen() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.manager.perform(.toggleOverview)
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func nothingIsRaisedDuringADrag() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()
    scenario.fixture.manager.perform(.focusRight)
    let session = try DragSession(scenario.row[1], in: scenario.fixture)

    session.move(to: CGPoint(x: 700, y: 400))
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func nothingIsRaisedDuringASwipe() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()
    scenario.fixture.manager.perform(.focusRight)

    scenario.fixture.gestures.onSwipe?(-0.05, .began)
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func nothingIsRaisedWithThePreferenceOff() throws {
    let scenario = try FloatingScenario(keepsFloatingWindowsOnTop: false)
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.source.focus(scenario.row[2])
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func theHiddenScratchpadWindowIsNeverRaised() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.manager.perform(.sendToScratchpad)
    scenario.fixture.source.userMoved(scenario.row[0], to: scenario.coveringFrame)

    scenario.fixture.manager.perform(.focusRight)
    scenario.letRaiseDelayPass()

    #expect(scenario.row[0].raiseCount == 0)
  }

  @Test func theShownScratchpadWindowIsRaisedWhenItCoversTheFocusedWindow() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.manager.perform(.sendToScratchpad)
    scenario.fixture.manager.perform(.toggleScratchpad)

    scenario.fixture.manager.perform(.focusRight)
    scenario.letRaiseDelayPass()

    #expect(scenario.row[0].raiseCount == 1)
  }
}
