import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewModelTests {
  private let size = OverviewSnapshots.size

  private final class Calls {
    var selected: [WindowID] = []
    var dismissed = 0
    var moves: [(WindowID, DropTarget)] = []
    var widths: [(WindowID, Double)] = []
    var heights: [(WindowID, Double, VerticalNeighbor)] = []
  }

  private func model(
    _ columns: [[UInt32]], tabbed: Set<Int> = []
  ) -> (OverviewModel, OverviewGeometry, Calls) {
    let snapshot = OverviewSnapshots.make(columns: columns, tabbed: tabbed)
    let model = OverviewModel()
    let calls = Calls()
    model.onSelect = { calls.selected.append($0) }
    model.onDismiss = { calls.dismissed += 1 }
    model.onMove = { calls.moves.append(($0, $1)) }
    model.onColumnWidth = { calls.widths.append(($0, $1)) }
    model.onRowHeight = { calls.heights.append(($0, $1, $2)) }
    model.show(snapshot)
    return (model, OverviewGeometry(snapshot: snapshot, size: size), calls)
  }

  private func drag(_ model: OverviewModel, from start: CGPoint, to end: CGPoint) {
    model.pressed(at: start, in: size)
    model.dragged(to: end, in: size)
    model.released(at: end, in: size)
  }

  @Test func pressAndReleaseOnACardSelectsIt() throws {
    let (model, geometry, calls) = model([[1], [2]])
    let point = try #require(geometry.cards.last).rect.center

    model.pressed(at: point, in: size)
    model.released(at: point, in: size)

    #expect(calls.selected == [WindowID(2)])
    #expect(calls.moves.isEmpty)
  }

  @Test func smallMovementStillCountsAsAClick() throws {
    let (model, geometry, calls) = model([[1], [2]])
    let point = try #require(geometry.cards.first).rect.center

    model.pressed(at: point, in: size)
    model.dragged(to: CGPoint(x: point.x + 3, y: point.y), in: size)
    model.released(at: point, in: size)

    #expect(calls.selected == [WindowID(1)])
  }

  @Test func pressAndReleaseOnTheBackdropDismisses() {
    let (model, _, calls) = model([[1]])

    model.pressed(at: CGPoint(x: 5, y: 5), in: size)
    model.released(at: CGPoint(x: 5, y: 5), in: size)

    #expect(calls.dismissed == 1)
  }

  @Test func draggingOnTheBackdropDoesNothing() {
    let (model, _, calls) = model([[1]])

    drag(model, from: CGPoint(x: 5, y: 5), to: CGPoint(x: 300, y: 5))

    #expect(calls.dismissed == 0 && calls.selected.isEmpty && calls.moves.isEmpty)
  }

  @Test func draggingACardLiftsItAndRearrangesTheOthers() throws {
    let (model, geometry, _) = model([[1], [2], [3]])
    let first = try #require(geometry.cards.first)
    let last = try #require(geometry.cards.last)

    model.pressed(at: first.rect.center, in: size)
    model.dragged(to: CGPoint(x: last.rect.midX, y: last.rect.maxY - 10), in: size)

    #expect(OverviewSnapshots.windows(model.arrangement) == [[2], [3, 1]])
    #expect(model.lift?.window == WindowID(1))
    #expect(model.lift?.rect.size == first.rect.size)
    #expect(OverviewSnapshots.windows(model.snapshot) == [[1], [2], [3]])
  }

  @Test func releasingADragCommitsTheTargetAndLeavesTheSnapshotAlone() throws {
    let (model, geometry, calls) = model([[1], [2], [3]])
    let first = try #require(geometry.cards.first)
    let last = try #require(geometry.cards.last)

    drag(model, from: first.rect.center, to: CGPoint(x: last.rect.midX, y: last.rect.minY + 10))

    #expect(calls.moves.count == 1)
    #expect(calls.moves.first?.0 == WindowID(1))
    #expect(calls.moves.first?.1 == .stack(onto: WindowID(3), side: .above))
    #expect(model.lift == nil)
    #expect(OverviewSnapshots.windows(model.arrangement) == [[1], [2], [3]])
  }

  @Test func draggingBetweenTwoColumnsPreviewsAColumnThere() throws {
    let (model, geometry, calls) = model([[1], [2], [3]])
    let first = try #require(geometry.cards.first)
    let second = geometry.cards[1]
    let third = geometry.cards[2]
    let gap = CGPoint(x: (second.rect.maxX + third.rect.minX) / 2, y: second.rect.midY)

    model.pressed(at: first.rect.center, in: size)
    model.dragged(to: gap, in: size)
    #expect(OverviewSnapshots.windows(model.arrangement) == [[2], [1], [3]])
    model.released(at: gap, in: size)

    #expect(calls.moves.first?.1 == .column(position: 1))
  }

  @Test func draggingOverNothingAnimatesBackWithoutACommit() throws {
    let (model, geometry, calls) = model([[1], [2]])
    let first = try #require(geometry.cards.first)

    model.pressed(at: first.rect.center, in: size)
    model.dragged(to: CGPoint(x: 500, y: 20), in: size)
    #expect(model.lift != nil)
    #expect(OverviewSnapshots.windows(model.arrangement) == [[1], [2]])
    model.released(at: CGPoint(x: 500, y: 20), in: size)

    #expect(calls.moves.isEmpty)
    #expect(model.lift == nil)
  }

  @Test func draggingAnEdgeResizesTheColumnLiveAndShowsThePercentage() throws {
    let (model, geometry, calls) = model([[1], [2]])
    let edge = try #require(geometry.hitAreas.edges.first)
    let start = CGPoint(x: edge.rect.minX + 4, y: edge.rect.midY)

    model.pressed(at: start, in: size)
    model.dragged(to: CGPoint(x: start.x + 40, y: start.y), in: size)

    #expect(model.arrangement.columns[0].width > model.snapshot.columns[0].width)
    #expect(model.arrangement.columns[1].width == model.snapshot.columns[1].width)
    #expect(model.resizeLabel?.window == WindowID(1))
    #expect(model.resizeLabel?.text.hasSuffix("%") == true)
    model.released(at: CGPoint(x: start.x + 40, y: start.y), in: size)
    #expect(calls.widths.count == 1)
    #expect(calls.widths.first?.0 == WindowID(1))
    #expect(model.resizeLabel == nil)
  }

  @Test func pressingAnEdgeWithoutMovingCommitsNothing() throws {
    let (model, geometry, calls) = model([[1], [2]])
    let edge = try #require(geometry.hitAreas.edges.first)
    let point = CGPoint(x: edge.rect.minX + 4, y: edge.rect.midY)

    model.pressed(at: point, in: size)
    model.released(at: point, in: size)

    #expect(calls.widths.isEmpty && calls.selected.isEmpty)
  }

  @Test func draggingADividerMovesHeightBetweenTheTwoRowsLive() throws {
    let (model, geometry, calls) = model([[1, 2, 3]])
    let divider = try #require(geometry.hitAreas.dividers.first)
    let start = divider.rect.center

    model.pressed(at: start, in: size)
    model.dragged(to: CGPoint(x: start.x, y: start.y + 30), in: size)

    let shares = model.arrangement.columns[0].cards.map(\.heightShare)
    #expect(shares[0] > 1.0 / 3.0 && shares[1] < 1.0 / 3.0)
    #expect(abs(shares[2] - 1.0 / 3.0) < 1e-9)
    #expect(model.activeDivider == WindowID(1))
    model.released(at: CGPoint(x: start.x, y: start.y + 30), in: size)
    #expect(calls.heights.count == 1)
    #expect(calls.heights.first?.0 == WindowID(1))
    #expect(calls.heights.first?.2 == .below)
  }

  @Test func theDividerNeverShrinksARowBelowTheMinimumShare() throws {
    let (model, geometry, calls) = model([[1, 2]])
    let divider = try #require(geometry.hitAreas.dividers.first)
    let start = divider.rect.center

    drag(model, from: start, to: CGPoint(x: start.x, y: start.y + 5000))

    #expect(calls.heights.first?.1 == 1 - Column.minimumHeightShare)
  }

  @Test func newSnapshotsReplaceTheArrangementWhenIdle() {
    let (model, _, _) = model([[1], [2]])

    model.show(OverviewSnapshots.make(columns: [[2], [1]]))

    #expect(OverviewSnapshots.windows(model.arrangement) == [[2], [1]])
  }
}
