import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragPollingCostTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.clock.advance(by: .seconds(1))
    return (fixture, row)
  }

  @Test func nothingIsScheduledWhileNoButtonIsDown() throws {
    let (fixture, _) = try launchedRow()

    #expect(fixture.clock.pendingScheduleCount == 0)
  }

  @Test func pollingRunsOnlyBetweenAPressOnATiledWindowAndItsRelease() throws {
    let (fixture, row) = try launchedRow()

    let session = try DragSession(row[0], in: fixture)
    #expect(fixture.clock.pendingScheduleCount == 1)
    session.letPollingRun()
    #expect(fixture.clock.pendingScheduleCount == 1)
    session.release()
    fixture.clock.advance(by: DragPoller.interval)

    #expect(fixture.clock.pendingScheduleCount == 0)
    let reads = fixture.pointer.serverBoundsReadCount
    fixture.clock.advance(by: .seconds(1))
    #expect(fixture.pointer.serverBoundsReadCount == reads)
  }

  @Test func pollingStopsWhenTheButtonIsFoundUpWithoutAnUpEvent() throws {
    let (fixture, row) = try launchedRow()
    let session = try DragSession(row[0], in: fixture)

    session.release(sendingEvent: false)
    fixture.clock.advance(by: DragPoller.interval)

    #expect(fixture.clock.pendingScheduleCount == 0)
  }

  @Test func pollingStopsAfterAMoveIsFinishedByTheUpEvent() throws {
    let (fixture, row) = try launchedRow()
    let session = try DragSession(row[0], in: fixture)
    session.moveSilently(to: CGPoint(x: 400, y: 5))
    session.letPollingRun()

    session.release()
    fixture.clock.advance(by: DragPoller.interval)

    #expect(fixture.clock.pendingScheduleCount == 0)
  }

  @Test func aPressOnEmptyDesktopSchedulesNothing() throws {
    let (fixture, _) = try launchedRow()
    fixture.pointer.windowAtPoint = { _ in nil }

    fixture.pointer.pressPrimary(at: CGPoint(x: 5, y: 5))

    #expect(fixture.clock.pendingScheduleCount == 0)
    fixture.pointer.releasePrimary()
  }

  @Test func aPressOnAFloatingWindowSchedulesNothing() throws {
    let scenario = try FloatingScenario()
    scenario.fixture.clock.advance(by: .seconds(1))

    #expect(scenario.fixture.clock.pendingScheduleCount == 0)
    scenario.fixture.pointer.windowAtPoint = { _ in 10 }

    scenario.fixture.pointer.pressPrimary(at: CGPoint(x: 50, y: 150))

    #expect(scenario.fixture.clock.pendingScheduleCount == 0)
    scenario.fixture.pointer.releasePrimary()
  }

  @Test func aNewPressReplacesThePollOfThePreviousOne() throws {
    let (fixture, row) = try launchedRow()
    let first = try DragSession(row[0], in: fixture)
    first.release(sendingEvent: false)

    let second = try DragSession(row[1], in: fixture)

    #expect(fixture.clock.pendingScheduleCount == 2)
    second.release()
    fixture.clock.advance(by: DragPoller.interval)
    #expect(fixture.clock.pendingScheduleCount == 0)
  }
}
