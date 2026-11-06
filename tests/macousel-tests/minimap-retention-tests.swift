import StripCore
import Testing

@testable import Macousel

@MainActor
struct MinimapRetentionTests {
  private let linger = OverlayTiming.minimapLinger

  private func fixture() -> MinimapModelFixture {
    MinimapModelFixture(snapshot: MinimapSnapshots.strip(columns: 4))
  }

  private var halfResolved: MinimapSnapshot {
    MinimapSnapshots.strip(
      columns: 4,
      replacing: [
        1: MinimapSnapshot.Column(
          x: 500, width: 492, rows: [], activeRow: 0, isTabbed: false, isFocused: false)
      ])
  }

  @Test func aColumnWithoutWindowsIsNotRenderable() {
    #expect(MinimapSnapshots.strip(columns: 4).isRenderable)
    #expect(!halfResolved.isRenderable)
    #expect(!MinimapSnapshot.empty.isRenderable)
  }

  @Test func aHalfResolvedSnapshotKeepsTheLastGoodOne() {
    let fixture = fixture()
    let good = fixture.model.snapshot
    fixture.model.show(halfResolved, update: .animated)
    #expect(fixture.model.snapshot == good)
    #expect(fixture.model.arrangement == good)
    #expect(fixture.model.isShown)
  }

  @Test func anEmptySnapshotKeepsTheLastGoodOneAndTheLinger() {
    let fixture = fixture()
    fixture.clock.advance(by: .milliseconds(500))
    fixture.model.show(.empty, update: .immediate)
    #expect(fixture.model.snapshot.columns.count == 4)
    fixture.clock.advance(by: linger - .milliseconds(1))
    #expect(fixture.model.isShown)
    fixture.clock.advance(by: .milliseconds(1))
    #expect(!fixture.model.isShown)
  }

  @Test func nothingShowsWithoutAGoodSnapshot() {
    let clock = ManualClock()
    let model = MinimapModel(now: { clock.now }, schedule: { clock.schedule(after: $0, $1) })
    model.show(.empty, update: .immediate)
    #expect(!model.isShown)
    #expect(clock.pendingScheduleCount == 0)
  }

  @Test func aBadSnapshotNeverRevivesAHiddenMinimap() {
    let fixture = fixture()
    fixture.clock.advance(by: linger)
    fixture.model.show(halfResolved, update: .immediate)
    #expect(!fixture.model.isShown)
    #expect(fixture.clock.pendingScheduleCount == 0)
  }

  @Test func releasingFadesOnTheLingerInsteadOfBlanking() {
    let fixture = fixture()
    fixture.clock.advance(by: .milliseconds(300))
    fixture.model.release()
    #expect(fixture.model.isShown)
    #expect(fixture.model.snapshot.columns.count == 4)
    fixture.clock.advance(by: linger - .milliseconds(300))
    #expect(!fixture.model.isShown)
  }

  @Test func repeatedReleasesDoNotExtendTheLinger() {
    let fixture = fixture()
    fixture.model.release()
    fixture.clock.advance(by: .milliseconds(500))
    fixture.model.release()
    fixture.clock.advance(by: linger - .milliseconds(500))
    #expect(!fixture.model.isShown)
  }

  @Test func aGoodSnapshotAfterAReleaseShowsAgainWithoutAGap() {
    let fixture = fixture()
    fixture.model.release()
    fixture.clock.advance(by: .milliseconds(800))
    fixture.model.show(MinimapSnapshots.strip(columns: 5), update: .animated)
    fixture.clock.advance(by: .milliseconds(800))
    #expect(fixture.model.isShown)
    #expect(fixture.model.snapshot.columns.count == 5)
    #expect(fixture.visibility.isEmpty)
  }

  @Test func releasingAHiddenMinimapResetsIt() {
    let fixture = fixture()
    fixture.clock.advance(by: linger)
    fixture.model.release()
    #expect(!fixture.model.isShown)
    #expect(fixture.clock.pendingScheduleCount == 0)
  }
}
