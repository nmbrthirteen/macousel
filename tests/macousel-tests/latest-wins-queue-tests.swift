import Foundation
import Testing
import os

@testable import WindowSystem

struct LatestWinsQueueTests {
  private final class Events: Sendable {
    private let recorded = OSAllocatedUnfairLock(initialState: [String]())

    var all: [String] { recorded.withLock { $0 } }

    func append(_ event: String) {
      recorded.withLock { $0.append(event) }
    }
  }

  private func queue(recording events: Events) -> LatestWinsQueue<Int> {
    LatestWinsQueue(
      quietDelay: 3_600, idleDelay: 3_600,
      apply: { window, _ in events.append("apply \(window)") },
      beginBurst: { events.append("begin \($0)") },
      endBurst: { events.append("end \($0)") },
      release: { events.append("release \($0)") })
  }

  @Test func flushEndsTheBurstAndReleasesAnIdleApp() {
    let events = Events()
    let queue = queue(recording: events)

    queue.submit(0, window: 7, pid: 42)
    queue.flush()

    #expect(events.all == ["begin 42", "apply 7", "end 42", "release 42"])
  }

  @Test func flushReleasesAnAppWhoseBurstAlreadyEnded() {
    let events = Events()
    let queue = queue(recording: events)
    queue.submit(0, window: 7, pid: 42)
    queue.flush()

    queue.flush()

    #expect(events.all.filter { $0 == "release 42" }.count == 2)
    #expect(events.all.filter { $0 == "end 42" }.count == 1)
  }

  @Test func theBurstEndsOnlyOnceAcrossBursts() {
    let events = Events()
    let queue = queue(recording: events)

    queue.submit(0, window: 7, pid: 42)
    queue.flush()
    queue.submit(1, window: 7, pid: 42)
    queue.flush()

    #expect(events.all.filter { $0 == "begin 42" }.count == 2)
    #expect(events.all.filter { $0 == "end 42" }.count == 2)
  }
}
