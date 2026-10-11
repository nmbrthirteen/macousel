import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct FocusWithoutRaisingTests {
  @Test func aCommandFocusUnderACoveringFloatingWindowDoesNotRaiseTheTiledWindow() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)

    #expect(scenario.row[1].nonRaisingFocusCount == 1)
    #expect(scenario.row[1].raisingFocusCount == 0)
    #expect(scenario.fixture.environment.isInFront(of: 10, 2))
  }

  @Test func aCommandFocusWithNoCoveringFloatingWindowRaisesAsBefore() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.source.userMoved(
      scenario.floater, to: CGRect(x: 0, y: Display.menuBarHeight, width: 4, height: 4))

    scenario.fixture.manager.perform(.focusRight)

    #expect(scenario.row[1].raisingFocusCount == 1)
    #expect(scenario.row[1].nonRaisingFocusCount == 0)
    #expect(scenario.fixture.environment.isInFront(of: 2, 10))
  }

  @Test func aFocusBeforeAnyFloatingFrameIsKnownRaisesAsBefore() throws {
    let scenario = try FloatingScenario()

    scenario.fixture.manager.perform(.focusRight)

    #expect(scenario.row[1].raisingFocusCount == 1)
  }

  @Test func switchingTabsRaisesTheNewTab() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.manager.perform(.stackLeft)
    scenario.fixture.manager.perform(.toggleTabbed)
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusUp)

    #expect(scenario.row[0].raisingFocusCount == 1)
    #expect(scenario.row[0].nonRaisingFocusCount == 0)
  }

  @Test func theFocusRaisesWhenThePreferenceIsOff() throws {
    let scenario = try FloatingScenario(keepsFloatingWindowsOnTop: false)
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)

    #expect(scenario.row[1].raisingFocusCount == 1)
    #expect(scenario.row[1].nonRaisingFocusCount == 0)
  }

  @Test func aSystemFocusEventStillTriggersTheKeeperAfterANonRaisingFocus() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()
    scenario.fixture.manager.perform(.focusRight)
    scenario.letRaiseDelayPass()
    let raisesAfterCommand = scenario.floater.raiseCount
    scenario.fixture.clock.advance(by: .milliseconds(300))

    scenario.fixture.source.focus(scenario.floater)
    scenario.fixture.source.focus(scenario.row[1])
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == raisesAfterCommand + 1)
  }
}
