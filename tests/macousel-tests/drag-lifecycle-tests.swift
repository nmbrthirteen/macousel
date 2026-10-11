import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragLifecycleTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    return (fixture, row)
  }

  @Test func aClickWithoutMovementChangesNothingAndShowsNoPreview() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let session = try DragSession(row[0], in: fixture)

    session.release()

    #expect(fixture.frames(of: row) == before)
    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
    #expect(row.allSatisfy { $0.framesSet.count == 1 })
  }

  @Test func draggingInsideTheWindowWithoutItMovingIsNotADrag() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let session = try DragSession(row[0], in: fixture)

    fixture.pointer.dragPrimary(to: CGPoint(x: 100, y: 300))
    fixture.pointer.dragPrimary(to: CGPoint(x: 200, y: 500))
    session.release()

    #expect(fixture.frames(of: row) == before)
    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
  }

  @Test func aWindowWhoseServerBoundsDifferFromTheRequestAtPressIsNotADragUntilItMoves() throws {
    let (fixture, row) = try launchedRow()
    let requested = try #require(row[0].frame)
    var snapped = requested
    snapped.size.width -= 7
    let before = fixture.frames(of: row)
    row[0].frame = snapped
    let session = try DragSession(row[0], in: fixture)

    fixture.pointer.dragPrimary(to: CGPoint(x: 100, y: 300))
    session.release()

    #expect(fixture.frames(of: [row[1], row[2]]) == before.filter { $0.key != 1 })
    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
  }

  @Test func aDragThatStartsOnEmptyDesktopIsIgnored() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    fixture.pointer.windowAtPoint = { _ in nil }

    fixture.pointer.pressPrimary(at: CGPoint(x: 5, y: 5))
    row[0].frame = try #require(row[0].serverFrame).offsetBy(dx: 300, dy: 0)
    fixture.pointer.dragPrimary(to: CGPoint(x: 305, y: 5))
    fixture.pointer.releasePrimary()

    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
    #expect(fixture.frames(of: [row[1], row[2]]) == before.filter { $0.key != 1 })
  }

  @Test func aDragThatStartsOnAFloatingWindowIsIgnored() throws {
    let scenario = try FloatingScenario()
    let before = scenario.fixture.frames(of: scenario.row)
    let session = try DragSession(scenario.floater, in: scenario.fixture)

    session.move(to: CGPoint(x: 500, y: 300))
    session.release()

    #expect(scenario.fixture.overlays.dropPreviewHistory.isEmpty)
    #expect(scenario.fixture.frames(of: scenario.row) == before)
  }

  @Test func aMovedNotificationAloneIsNotADrag() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let grabbed = try #require(row[0].frame)

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.source.userMoved(row[0], to: grabbed.offsetBy(dx: 700, dy: 0))
    fixture.pointer.releasePrimary()

    #expect(fixture.frames(of: [row[1], row[2]]) == before.filter { $0.key != 1 })
    #expect(row[0].framesSet.count == 1)
    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
  }

  @Test func escapeCancelsALiveMoveAndTheWindowReturnsToItsSlot() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let target = try #require(row[2].frame)
    let session = try DragSession(row[0], in: fixture)
    session.move(to: CGPoint(x: target.midX, y: target.minY + 10))
    #expect(fixture.pointer.isObservingEscape)
    #expect(fixture.overlays.dropPreview != nil)

    fixture.pointer.pressEscape()

    #expect(fixture.overlays.dropPreview == nil)
    #expect(!fixture.pointer.isObservingEscape)
    #expect(fixture.frames(of: row) == before)
    session.move(to: CGPoint(x: target.midX, y: target.maxY - 10))
    session.release()
    #expect(fixture.frames(of: row) == before)
    #expect(fixture.overlays.dropPreview == nil)
  }

  @Test func escapeIsOnlyWatchedWhileADragIsLive() throws {
    let (fixture, row) = try launchedRow()
    #expect(!fixture.pointer.isObservingEscape)
    let session = try DragSession(row[0], in: fixture)
    #expect(!fixture.pointer.isObservingEscape)

    session.move(to: CGPoint(x: 400, y: 5))
    #expect(fixture.pointer.isObservingEscape)
    session.release()

    #expect(!fixture.pointer.isObservingEscape)
  }

  @Test func rightEdgeResizeMakesTheColumnFixedWidthAndShowsNoPreview() throws {
    let (fixture, row) = try launchedRow()
    var resized = try #require(row[1].frame)
    resized.size.width += 100
    let session = try DragSession(row[1], in: fixture, atX: 0.99)

    session.resize(to: resized, pointerAt: CGPoint(x: resized.maxX - 2, y: resized.midY))
    session.release()

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(resized.width, of: WindowID(2)) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
  }

  @Test func theLiveWindowIsNotRepositionedUntilRelease() throws {
    let (fixture, row) = try launchedRow()
    let session = try DragSession(row[0], in: fixture)
    session.move(to: CGPoint(x: 700, y: 400))
    let moved = row[0].serverFrame

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.moveLeft)

    #expect(row[0].serverFrame == moved)
    #expect(row[0].framesSet.count == 1)
    session.release()
  }

  @Test func noWindowFrameIsReadThroughAccessibilityDuringADrag() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)
    let reads = row.map(\.frameReadCount)

    let session = try DragSession(row[0], in: fixture)
    session.move(to: CGPoint(x: target.midX, y: target.minY + 10))
    session.move(to: CGPoint(x: target.maxX - 10, y: target.midY))
    session.release()

    #expect(row.map(\.frameReadCount) == reads)
  }
}
