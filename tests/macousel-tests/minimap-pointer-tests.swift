import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct MinimapPointerTests {
  private func fixture(columns: Int = 4) -> MinimapModelFixture {
    MinimapModelFixture(snapshot: MinimapSnapshots.strip(columns: columns))
  }

  private func windows(_ snapshot: MinimapSnapshot) -> [[UInt32]] {
    snapshot.columns.map { $0.rows.map(\.window.rawValue) }
  }

  @Test func clickingACellSelectsItsWindow() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(3)
    fixture.model.click(CGPoint(x: cell.rect.midX, y: cell.rect.midY))
    #expect(fixture.selected == [WindowID(3)])
    #expect(fixture.moves.isEmpty)
  }

  @Test func clickingBetweenCellsSelectsNothing() {
    let fixture = fixture()
    fixture.model.click(CGPoint(x: 2, y: 2))
    #expect(fixture.selected.isEmpty)
  }

  @Test func aClickKeepsTheMinimapOnScreenWhileThePointerStaysOver() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(2)
    fixture.model.click(CGPoint(x: cell.rect.midX, y: cell.rect.midY))
    fixture.clock.advance(by: .seconds(30))
    #expect(fixture.model.isShown)
  }

  @Test func movementUnderTheThresholdIsStillAClick() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(2)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    fixture.model.drag(from: start, to: CGPoint(x: start.x + 3, y: start.y))
    #expect(fixture.selected == [WindowID(2)])
    #expect(fixture.model.lift == nil)
  }

  @Test func draggingPastTheThresholdLiftsTheCellAndSlidesTheOthers() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    let target = try fixture.model.cell(3).rect
    fixture.model.pressed(at: start)
    fixture.model.dragged(to: CGPoint(x: target.maxX - 2, y: start.y))
    #expect(fixture.model.lift?.cell == cell.id)
    #expect(windows(fixture.model.arrangement) == [[2], [3], [1], [4]])
    #expect(windows(fixture.model.snapshot) == [[1], [2], [3], [4]])
  }

  @Test func theLiftedCellFollowsThePointerHorizontally() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    fixture.model.pressed(at: start)
    fixture.model.dragged(to: CGPoint(x: start.x + 60, y: start.y))
    #expect(fixture.model.lift?.offset == 60)
  }

  @Test func theLiftedCellStaysInsideTheContainer() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    fixture.model.pressed(at: start)
    fixture.model.dragged(to: CGPoint(x: -300, y: start.y))
    #expect(fixture.model.lift?.offset == -Double(cell.rect.minX))
  }

  @Test func releasingBesideAnotherColumnMovesTheWindowToItsOwnColumn() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let last = try fixture.model.cell(4).rect
    fixture.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: last.maxX - 2, y: last.midY))
    #expect(fixture.moves.map(\.window) == [WindowID(1)])
    #expect(fixture.moves.map(\.target) == [.column(position: 3)])
    #expect(fixture.selected.isEmpty)
  }

  @Test(arguments: [(0.25, VerticalNeighbor.above), (0.75, VerticalNeighbor.below)])
  func releasingOnTheMiddleOfACellStacksItOnTheHalfUnderThePointer(
    fraction: Double, side: VerticalNeighbor
  ) throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let destination = try fixture.model.cell(3).rect
    fixture.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: destination.midX, y: destination.minY + destination.height * fraction))
    #expect(fixture.moves.map(\.target) == [.stack(onto: WindowID(3), side: side)])
  }

  @Test func theArrangementPreviewsAStack() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let destination = try fixture.model.cell(3).rect
    fixture.model.pressed(at: CGPoint(x: cell.rect.midX, y: cell.rect.midY))
    fixture.model.dragged(
      to: CGPoint(x: destination.midX, y: destination.minY + destination.height * 0.75))
    #expect(windows(fixture.model.arrangement) == [[2], [3, 1], [4]])
  }

  @Test func releasingOutsideTheMinimapCancels() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    fixture.model.pressed(at: start)
    fixture.model.dragged(to: CGPoint(x: start.x + 40, y: start.y))
    fixture.model.released(at: CGPoint(x: start.x + 40, y: Metrics.Minimap.height + 60))
    #expect(fixture.moves.isEmpty)
    #expect(fixture.selected.isEmpty)
    #expect(fixture.model.lift == nil)
    #expect(fixture.model.arrangement == fixture.model.snapshot)
  }

  @Test func draggingOutsideShowsTheOriginalArrangement() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    fixture.model.pressed(at: CGPoint(x: cell.rect.midX, y: cell.rect.midY))
    fixture.model.dragged(to: CGPoint(x: cell.rect.midX, y: -80))
    #expect(fixture.model.arrangement == fixture.model.snapshot)
    #expect(fixture.model.lift != nil)
  }

  @Test func droppingWhereItAlreadySitsCancels() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(2)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    fixture.model.drag(from: start, to: CGPoint(x: start.x + 12, y: start.y))
    #expect(fixture.moves.isEmpty)
    #expect(fixture.selected.isEmpty)
  }

  @Test func theMinimapStaysDuringADragAndStartsTheTimerAfterAnOutsideRelease() throws {
    let fixture = fixture()
    let cell = try fixture.model.cell(1)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    fixture.model.pressed(at: start)
    fixture.model.dragged(to: CGPoint(x: start.x + 30, y: start.y))
    fixture.clock.advance(by: .seconds(10))
    #expect(fixture.model.isShown)
    fixture.model.released(at: CGPoint(x: start.x + 30, y: 200))
    fixture.clock.advance(by: OverlayTiming.minimapLinger)
    #expect(!fixture.model.isShown)
  }

  @Test func aTabbedColumnDragsItsActiveWindow() throws {
    let column = MinimapSnapshot.Column(
      x: 0, width: 492, rows: (11...13).map { MinimapSnapshots.row($0) }, activeRow: 1,
      isTabbed: true, isFocused: true)
    let snapshot = MinimapSnapshots.strip(columns: 4, replacing: [0: column])
    let fixture = MinimapModelFixture(snapshot: snapshot)
    let cell = try #require(fixture.model.geometry.cells.first)
    let last = try #require(fixture.model.geometry.cells.last).rect
    fixture.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: last.maxX - 2, y: last.midY))
    #expect(fixture.moves.map(\.window) == [WindowID(12)])
  }

  @Test func theGapBetweenStackedRowsStillTargetsTheStack() throws {
    let column = MinimapSnapshot.Column(
      x: 4 * 500, width: 492,
      rows: [MinimapSnapshots.row(15, height: 350), MinimapSnapshots.row(16, height: 350)],
      activeRow: 0, isTabbed: false, isFocused: false)
    let snapshot = MinimapSnapshots.strip(columns: 5, replacing: [4: column])
    let fixture = MinimapModelFixture(snapshot: snapshot)
    let cell = try fixture.model.cell(1)
    let upper = try fixture.model.cell(15).rect
    let lower = try fixture.model.cell(16).rect
    fixture.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: upper.midX, y: (upper.maxY + lower.minY) / 2))
    #expect(fixture.moves.count == 1)
  }
}
