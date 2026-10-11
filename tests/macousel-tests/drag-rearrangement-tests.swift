import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragRearrangementTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    return (fixture, row)
  }

  private func leftBand(of window: FakeWindow) throws -> CGPoint {
    let frame = try #require(window.frame)
    return CGPoint(x: frame.minX + 10, y: frame.midY)
  }

  private let nowhere = CGPoint(x: 400, y: 5)

  @Test func neighboursMoveAsSoonAsThePointerEntersANewZone() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let band = try leftBand(of: row[1])
    let session = try DragSession(row[2], in: fixture)
    #expect(fixture.frames(of: row) == before)

    session.move(to: band)

    #expect(row[1].frame != before[2])
    #expect(row[1].frame != before[1])
    #expect(row[0].frame == before[1])
    #expect(row[2].framesSet.count == 1)
    session.release()
  }

  @Test func leavingEveryZoneRestoresTheStartingFrames() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let session = try DragSession(row[2], in: fixture)
    session.move(to: try leftBand(of: row[1]))

    session.move(to: nowhere)

    #expect(fixture.frames(of: [row[0], row[1]]) == before.filter { $0.key != 3 })
    #expect(fixture.overlays.dropPreview == nil)
    session.release()
    #expect(fixture.frames(of: row) == before)
  }

  @Test func escapeRestoresTheStartingFrames() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let session = try DragSession(row[2], in: fixture)
    session.move(to: try leftBand(of: row[1]))

    fixture.pointer.pressEscape()

    #expect(fixture.frames(of: row) == before)
    session.release()
    #expect(fixture.frames(of: row) == before)
  }

  @Test func releaseLeavesExactlyTheArrangementThatWasShown() throws {
    let (fixture, row) = try launchedRow()
    let session = try DragSession(row[2], in: fixture)
    session.move(to: try leftBand(of: row[1]))
    let shown = fixture.frames(of: [row[0], row[1]])
    let submissions = fixture.placer.submissions.count

    let preview = session.release()

    #expect(fixture.frames(of: [row[0], row[1]]) == shown)
    #expect(row[2].frame == preview)
    #expect(fixture.placer.submissions.count == submissions + 1)
  }

  @Test func aPointerRestingOnAZoneAfterNeighboursMovedDoesNotFlipTheTarget() throws {
    let (fixture, row) = try launchedRow()
    let session = try DragSession(row[2], in: fixture)
    let band = try leftBand(of: row[1])
    session.move(to: band)
    let shown = fixture.frames(of: row)
    let submissions = fixture.placer.submissions.count
    let preview = fixture.overlays.dropPreview

    for _ in 0..<3 { fixture.pointer.dragPrimary(to: band) }

    #expect(fixture.frames(of: [row[0], row[1]]) == shown.filter { $0.key != 3 })
    #expect(fixture.placer.submissions.count == submissions)
    #expect(fixture.overlays.dropPreview == preview)
    session.release()
  }

  @Test func theStripReturnsToItsStartWhenTheDragIsAbandonedOnNothing() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let session = try DragSession(row[2], in: fixture)
    session.move(to: try leftBand(of: row[1]))
    session.move(to: nowhere)

    session.release()

    #expect(fixture.frames(of: row) == before)
  }
}
