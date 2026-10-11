import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ScratchpadReconcileTests {
  private func harness(windows: CGWindowID) throws -> ReconcilerHarness {
    let harness = ReconcilerHarness(suite: try IsolatedDefaults())
    for id in 1...windows { harness.open(id, atX: CGFloat(id) * 100) }
    harness.reconciler.reconcile()
    return harness
  }

  @Test func reconcilingRemovesTheScratchpadWindowFromTheStripAndNeverAdmitsItAgain() throws {
    let harness = try harness(windows: 3)
    #expect(harness.scratchpad.send(2, from: harness.key()))

    harness.reconciler.reconcile()
    harness.reconciler.reconcile()

    #expect(harness.order() == [1, 3])
    #expect(harness.scratchpad.holds(2))
  }

  @Test func reconcilingEmptiesTheScratchpadWhenItsWindowIsClosed() throws {
    let harness = try harness(windows: 3)
    #expect(harness.scratchpad.send(2, from: harness.key()))
    harness.reconciler.reconcile()

    harness.source.close(try #require(harness.source.window(2) as? FakeWindow))
    harness.reconciler.reconcile()

    #expect(harness.scratchpad.window == nil)
    #expect(harness.order() == [1, 3])
  }

  @Test func sendingToTheScratchpadReplacesThePreviousWindow() throws {
    let harness = try harness(windows: 3)
    #expect(harness.scratchpad.send(1, from: harness.key()))
    harness.reconciler.reconcile()
    #expect(harness.scratchpad.send(3, from: harness.key()))

    harness.reconciler.reconcile()

    #expect(harness.scratchpad.window == 3)
    #expect(!harness.scratchpad.holds(1))
    #expect(Set(harness.order()) == [1, 2])
  }
}
