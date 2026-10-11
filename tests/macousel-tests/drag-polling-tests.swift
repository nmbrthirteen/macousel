import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragPollingTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.clock.advance(by: .seconds(1))
    return (fixture, row)
  }

  private func expectedRow(_ zone: DropZone) -> ExpectedStrip {
    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { zone.apply(to: &$0) }
    return expected
  }

  @Test func theRealUpEventIsNotNeededToSeeThatAMoveStarted() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)
    let session = try DragSession(row[0], in: fixture)

    session.moveSilently(to: CGPoint(x: target.midX, y: target.minY + 10))
    #expect(fixture.overlays.dropPreview == nil)
    session.letPollingRun()

    #expect(fixture.overlays.dropPreview != nil)
    session.release()
  }

  @Test(arguments: DropZone.allCases)
  func aMoveNoticedOnlyByThePollDropsOnEveryZone(zone: DropZone) throws {
    let (fixture, row) = try launchedRow()
    let point = zone.point(among: try row.map { try #require($0.frame) })
    let session = try DragSession(row[zone.draggedIndex], in: fixture)

    session.moveSilently(to: point)
    session.letPollingRun()
    session.release()

    #expect(fixture.frames(of: row) == expectedRow(zone).frames)
  }

  @Test(arguments: DropZone.allCases)
  func aMoveWhoseUpEventNeverArrivesStillDropsOnEveryZone(zone: DropZone) throws {
    let (fixture, row) = try launchedRow()
    let point = zone.point(among: try row.map { try #require($0.frame) })
    let session = try DragSession(row[zone.draggedIndex], in: fixture)

    session.moveSilently(to: point)
    session.letPollingRun()
    session.release(sendingEvent: false)
    session.letPollingRun()

    #expect(fixture.frames(of: row) == expectedRow(zone).frames)
    #expect(fixture.overlays.dropPreview == nil)
  }

  @Test func aMoveReleasedOnNothingWithoutAnUpEventReturnsToItsSlot() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let session = try DragSession(row[0], in: fixture)

    session.moveSilently(to: CGPoint(x: 400, y: 5))
    session.letPollingRun()
    session.release(sendingEvent: false)
    session.letPollingRun()

    #expect(fixture.frames(of: row) == before)
    #expect(fixture.overlays.dropPreview == nil)
    #expect(row[0].framesSet.count == 2)
  }

  @Test func aMoveReleasedOnNothingWithTheUpEventReturnsToItsSlot() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let session = try DragSession(row[0], in: fixture)

    session.moveSilently(to: CGPoint(x: 400, y: 5))
    session.letPollingRun()
    session.release()

    #expect(fixture.frames(of: row) == before)
    #expect(row[0].framesSet.count == 2)
  }

  @Test func theUpEventThatArrivesAfterThePollFinishedTheDragChangesNothing() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)
    let session = try DragSession(row[0], in: fixture)
    session.moveSilently(to: CGPoint(x: target.midX, y: target.minY + 10))
    session.letPollingRun()
    session.release(sendingEvent: false)
    session.letPollingRun()
    let dropped = fixture.frames(of: row)
    let submissions = fixture.placer.submissions.count

    fixture.pointer.releasePrimary()

    #expect(fixture.frames(of: row) == dropped)
    #expect(fixture.placer.submissions.count == submissions)
  }

  @Test func aResizeNoticedOnlyByThePollIsCommittedOnRelease() throws {
    let (fixture, row) = try launchedRow()
    var resized = try #require(row[1].frame)
    resized.size.width += 100
    let session = try DragSession(row[1], in: fixture, atX: 0.99)

    session.resizeSilently(to: resized, pointerAt: CGPoint(x: resized.maxX - 2, y: resized.midY))
    session.letPollingRun()
    session.release(sendingEvent: false)
    session.letPollingRun()

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(resized.width, of: WindowID(2)) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
  }

  @Test func aResizeNoticedOnlyByThePollWithTheUpEventIsCommittedOnRelease() throws {
    let (fixture, row) = try launchedRow()
    var resized = try #require(row[1].frame)
    resized.size.width += 100
    let session = try DragSession(row[1], in: fixture, atX: 0.99)

    session.resizeSilently(to: resized, pointerAt: CGPoint(x: resized.maxX - 2, y: resized.midY))
    session.letPollingRun()
    session.release()

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(resized.width, of: WindowID(2)) }
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func thePreviewFollowsTheLatestPolledPosition() throws {
    let (fixture, row) = try launchedRow()
    let first = try #require(row[2].frame)
    let session = try DragSession(row[0], in: fixture)

    session.moveSilently(to: CGPoint(x: first.midX, y: first.minY + 10))
    session.letPollingRun(frames: 1)
    let stackedPreview = try #require(fixture.overlays.dropPreview)
    session.moveSilently(to: CGPoint(x: 400, y: 5))
    session.letPollingRun(frames: 1)

    #expect(stackedPreview.height < first.height)
    #expect(fixture.overlays.dropPreview == nil)
    session.release()
  }
}
