import Dispatch
import Testing
import os

@testable import WindowSystem

struct LatestWinsQueueOrderingTests {
  private final class Events: Sendable {
    private let recorded = OSAllocatedUnfairLock(initialState: [String]())

    var all: [String] { recorded.withLock { $0 } }

    func append(_ event: String) {
      recorded.withLock { $0.append(event) }
    }
  }

  private func queue(
    recording events: Events, holding gate: DispatchSemaphore? = nil
  ) -> LatestWinsQueue<Int> {
    LatestWinsQueue(
      quietDelay: 3_600, idleDelay: 3_600,
      apply: { window, _ in
        events.append("apply \(window)")
        gate?.wait()
      },
      beginBurst: { _ in },
      endBurst: { _ in },
      release: { _ in })
  }

  @Test func anAppWithNothingQueuedHasNoWorkAndRunsTheActionInline() {
    let events = Events()
    let queue = queue(recording: events)

    queue.afterPending(42) { events.append("after") }

    #expect(!queue.hasWork(for: 42))
    #expect(events.all == ["after"])
  }

  @Test func theActionRunsOnlyAfterTheQueuedPlacementWork() {
    let events = Events()
    let gate = DispatchSemaphore(value: 0)
    let queue = queue(recording: events, holding: gate)

    queue.submit(0, window: 7, pid: 42)
    let hasWork = queue.hasWork(for: 42)
    queue.afterPending(42) { events.append("after") }
    gate.signal()
    queue.flush()

    #expect(hasWork)
    #expect(events.all == ["apply 7", "after"])
    #expect(!queue.hasWork(for: 42))
  }

  @Test func workQueuedForAnotherAppDoesNotHoldTheAction() {
    let events = Events()
    let gate = DispatchSemaphore(value: 0)
    let queue = queue(recording: events, holding: gate)

    queue.submit(0, window: 7, pid: 42)
    queue.submit(0, window: 8, pid: 43)

    #expect(!queue.hasWork(for: 44))
    gate.signal()
    gate.signal()
    queue.flush()
  }
}
