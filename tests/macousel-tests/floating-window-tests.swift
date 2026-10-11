import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct FloatingWindowTests {
  @Test func focusingATiledWindowByCommandRaisesAFloatingWindowThatCoversIt() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 1)
    #expect(scenario.row[1].raiseCount == 0)
    #expect(scenario.fixture.source.focusedWindow()?.id == 2)
    #expect(scenario.fixture.environment.isInFront(of: 10, 2))
  }

  @Test func theRaiseWaitsForTheDelay() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.clock.advance(by: FloatingWindowKeeper.raiseDelay - .milliseconds(1))

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func aFloatingWindowThatDoesNotCoverTheFocusedWindowIsNotRaised() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.manager.perform(.focusRight)
    let target = try #require(scenario.row[1].frame)

    scenario.fixture.source.userMoved(
      scenario.floater,
      to: CGRect(x: target.minX - 120, y: target.minY, width: 100, height: 100))
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func aFloatingWindowThatOnlyGrazesTheFocusedWindowIsNotRaised() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.manager.perform(.focusRight)
    let target = try #require(scenario.row[1].frame)
    let grazing = FloatingWindowKeeper.minimumOverlap / 2

    scenario.fixture.source.userMoved(
      scenario.floater,
      to: CGRect(x: target.minX - 100 + grazing, y: target.minY, width: 100, height: 100))
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
  }

  @Test func overlappingFloatingWindowsAreRaisedBackToFrontKeepingTheirOrder() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()
    let second = scenario.addFloater(11, covering: scenario.coveringFrame)
    scenario.fixture.environment.stack(frontToBack: [11, 10, 1, 2, 3])

    scenario.fixture.manager.perform(.focusRight)
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 1)
    #expect(second.raiseCount == 1)
    #expect(scenario.fixture.environment.isInFront(of: 11, 10))
    #expect(scenario.fixture.environment.isInFront(of: 10, 2))
  }

  @Test func aSystemFocusEventForATiledWindowRaisesTheFloatingWindowsToo() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.source.focus(scenario.row[1])
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 1)
    #expect(scenario.fixture.environment.isInFront(of: 10, 2))
  }

  @Test func theEchoOfACommandFocusDoesNotRaiseASecondTime() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.source.focus(scenario.row[1])
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 1)
  }

  @Test func aFocusEventForAFloatingWindowRaisesNothing() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.source.focus(scenario.floater)
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 0)
    #expect(scenario.row.allSatisfy { $0.raiseCount == 0 })
  }

  @Test func focusingAFloatingWindowAfterATiledOneAllowsTheTiledOneToRaiseAgain() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()
    scenario.fixture.source.focus(scenario.row[1])
    scenario.letRaiseDelayPass()

    scenario.fixture.source.focus(scenario.floater)
    scenario.fixture.source.focus(scenario.row[1])
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 2)
  }

  @Test func aSecondFocusBeforeTheDelayReplacesTheFirst() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()

    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.clock.advance(by: FloatingWindowKeeper.raiseDelay / 2)
    scenario.fixture.manager.perform(.focusRight)
    scenario.fixture.clock.advance(by: FloatingWindowKeeper.raiseDelay / 2)

    #expect(scenario.floater.raiseCount == 0)

    scenario.fixture.clock.advance(by: FloatingWindowKeeper.raiseDelay / 2)

    #expect(scenario.floater.raiseCount == 1)
  }

  @Test func theKeeperReadsNoFrameWhenTheFocusIsRequested() throws {
    let scenario = try FloatingScenario()
    scenario.coverTheScreen()
    let floaterReads = scenario.floater.frameReadCount
    let rowReads = scenario.row.map(\.frameReadCount)

    scenario.fixture.manager.perform(.focusRight)
    scenario.letRaiseDelayPass()

    #expect(scenario.floater.raiseCount == 1)
    #expect(scenario.floater.frameReadCount == floaterReads)
    #expect(scenario.row.map(\.frameReadCount) == rowReads)
  }
}
