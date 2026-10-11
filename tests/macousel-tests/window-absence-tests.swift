import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct WindowAbsenceTests {
  private func harness(windows: CGWindowID) throws -> ReconcilerHarness {
    let harness = ReconcilerHarness(suite: try IsolatedDefaults())
    for id in 1...windows { harness.open(id, atX: CGFloat(id) * 100) }
    harness.reconciler.reconcile()
    return harness
  }

  @Test func aSingleMissedOnScreenSampleKeepsTheColumnWidthAndOrder() throws {
    let harness = try harness(windows: 3)
    let key = harness.key()
    harness.state.workspaces[key]?.strip.setFixedWidth(320, of: WindowID(2))
    let before = harness.strip()

    harness.environment.hide(2)
    harness.reconciler.reconcile()

    #expect(harness.order() == [1, 2, 3])
    #expect(harness.strip().columns == before.columns)
  }

  @Test func aWindowReturningAfterOneMissedSampleResetsTheCount() throws {
    let harness = try harness(windows: 3)

    harness.environment.hide(2)
    harness.reconciler.reconcile()
    harness.environment.show(2)
    harness.reconciler.reconcile()
    harness.environment.hide(2)
    harness.reconciler.reconcile()

    #expect(harness.order() == [1, 2, 3])
  }

  @Test func twoConsecutiveMissedSamplesRemoveTheWindow() throws {
    let harness = try harness(windows: 3)

    harness.environment.hide(2)
    harness.reconciler.reconcile()
    harness.reconciler.reconcile()

    #expect(harness.order() == [1, 3])
  }

  @Test func aClosedWindowIsRemovedOnTheFirstSample() throws {
    let harness = try harness(windows: 3)
    let closing = try #require(harness.source.window(2) as? FakeWindow)

    harness.source.close(closing)
    harness.reconciler.reconcile()

    #expect(harness.order() == [1, 3])
  }

  @Test func theFirstSampleAfterASpaceChangeDoesNotPullWindowsOutOfTheOldSpace() throws {
    let harness = try harness(windows: 2)

    harness.environment.switchSpace(of: .fake(), to: 2, showing: [1, 2])
    harness.reconciler.reconcile()

    #expect(harness.order(space: 1) == [1, 2])
  }

  @Test func windowsStaleInTheNewSpaceNeverLeaveTheOldSpace() throws {
    let harness = try harness(windows: 2)
    harness.open(3, atX: 300)

    harness.environment.switchSpace(of: .fake(), to: 2, showing: [1, 2])
    harness.reconciler.reconcile()
    harness.environment.switchSpace(of: .fake(), to: 2, showing: [3])
    harness.reconciler.reconcile()

    #expect(harness.order(space: 1) == [1, 2])
    #expect(harness.order(space: 2).contains(3))
  }

  @Test func aWindowShownOnTheCurrentSpaceLeavesTheOldSpaceOnceTheSpaceIsSettled() throws {
    let harness = try harness(windows: 2)

    harness.environment.switchSpace(of: .fake(), to: 2, showing: [1, 2])
    harness.reconciler.reconcile()
    harness.reconciler.reconcile()

    #expect(harness.order(space: 1).isEmpty)
    #expect(harness.order(space: 2) == [1, 2])
  }
}
