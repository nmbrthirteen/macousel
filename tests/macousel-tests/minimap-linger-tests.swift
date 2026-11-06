import Observation
import os
import StripCore
import Testing

@testable import Macousel

@MainActor
struct MinimapLingerTests {
  private let linger = OverlayTiming.minimapLinger

  private func fixture() -> MinimapModelFixture {
    MinimapModelFixture(snapshot: MinimapSnapshots.strip(columns: 4))
  }

  @Test func aSwipeOfManyEventsKeepsOneTimerPending() {
    let fixture = fixture()
    for step in 0..<100 {
      fixture.clock.advance(by: .milliseconds(8))
      fixture.model.show(
        MinimapSnapshots.strip(columns: 4, viewportOffset: Double(step)), update: .immediate)
    }
    #expect(fixture.clock.pendingScheduleCount == 1)
  }

  @Test func theMinimapHidesOneLingerAfterTheLastEvent() {
    let fixture = fixture()
    for _ in 0..<50 {
      fixture.clock.advance(by: .milliseconds(100))
      fixture.model.show(MinimapSnapshots.strip(columns: 4), update: .immediate)
    }
    fixture.clock.advance(by: linger - .milliseconds(1))
    #expect(fixture.model.isShown)
    #expect(fixture.clock.pendingScheduleCount == 1)
    fixture.clock.advance(by: .milliseconds(1))
    #expect(!fixture.model.isShown)
    #expect(fixture.visibility == [false])
  }

  @Test func noTimerIsLeftOnceTheMinimapHides() {
    let fixture = fixture()
    fixture.clock.advance(by: .milliseconds(400))
    fixture.model.show(MinimapSnapshots.strip(columns: 4), update: .immediate)
    fixture.clock.advance(by: .seconds(5))
    #expect(!fixture.model.isShown)
    #expect(fixture.clock.pendingScheduleCount == 0)
  }

  @Test func showingTheSameSnapshotPublishesNothing() {
    let fixture = fixture()
    let changed = OSAllocatedUnfairLock(initialState: false)
    withObservationTracking {
      _ = fixture.model.snapshot
      _ = fixture.model.arrangement
      _ = fixture.model.isShown
    } onChange: {
      changed.withLock { $0 = true }
    }
    fixture.model.show(MinimapSnapshots.strip(columns: 4), update: .animated)
    #expect(!changed.withLock { $0 })
  }

  @Test func aNewSnapshotIsPublished() {
    let fixture = fixture()
    fixture.model.show(MinimapSnapshots.strip(columns: 4, focused: 2), update: .immediate)
    #expect(fixture.model.arrangement.focusedWindow == WindowID(3))
  }
}
