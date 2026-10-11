import CoreGraphics
import Testing

@testable import StripCore

struct DropRuleTests {
  private let row = DropGrid([[1], [2], [3]])

  @Test func upperHalfOfTheMiddleStacksAbove() {
    #expect(row.target(dragging: 1, at: 270, 100) == .stack(onto: id(3), side: .above))
  }

  @Test func lowerHalfOfTheMiddleStacksBelow() {
    #expect(row.target(dragging: 1, at: 270, 300) == .stack(onto: id(3), side: .below))
  }

  @Test func leftBandPutsTheWindowBeforeTheColumn() {
    #expect(row.target(dragging: 1, at: 225, 200) == .column(position: 1))
  }

  @Test func rightBandPutsTheWindowAfterTheColumn() {
    #expect(row.target(dragging: 1, at: 315, 200) == .column(position: 2))
  }

  @Test func gapBetweenColumnsPutsTheWindowBetweenThem() {
    #expect(row.target(dragging: 1, at: 215, 200) == .column(position: 1))
  }

  @Test func spaceRightOfTheLastColumnPutsTheWindowLast() {
    #expect(row.target(dragging: 1, at: 400, 200) == .column(position: 2))
  }

  @Test func spaceLeftOfTheFirstColumnPutsTheWindowFirst() {
    #expect(row.target(dragging: 3, at: 5, 200) == .column(position: 0))
    #expect(row.target(dragging: 1, at: -40, 200) == .nowhere)
  }

  @Test func outsideTheVerticalExtentIsNowhere() {
    #expect(row.target(dragging: 1, at: 400, 450) == .nowhere)
    #expect(row.target(dragging: 1, at: 400, -1) == .nowhere)
    #expect(row.target(dragging: 1, at: 215, 401) == .nowhere)
  }

  @Test func stackZoneIncludesItsBoundaries() {
    #expect(row.target(dragging: 1, at: 130, 100) == .stack(onto: id(2), side: .above))
    #expect(row.target(dragging: 1, at: 190, 100) == .stack(onto: id(2), side: .above))
  }

  @Test func justOutsideTheStackZoneIsABand() {
    #expect(row.target(dragging: 1, at: 129.9, 100) == .nowhere)
    #expect(row.target(dragging: 1, at: 190.1, 100) == .column(position: 1))
    #expect(row.target(dragging: 3, at: 129.9, 100) == .column(position: 1))
  }

  @Test func theMiddleLineBelongsToTheLowerHalf() {
    #expect(row.target(dragging: 1, at: 160, 199.9) == .stack(onto: id(2), side: .above))
    #expect(row.target(dragging: 1, at: 160, 200) == .stack(onto: id(2), side: .below))
  }

  @Test func frameEdgesStillCount() {
    #expect(row.target(dragging: 1, at: 160, 0) == .stack(onto: id(2), side: .above))
    #expect(row.target(dragging: 1, at: 160, 400) == .stack(onto: id(2), side: .below))
    #expect(row.target(dragging: 1, at: 210, 200) == .column(position: 1))
  }

  @Test func verticalGapBetweenStackedRowsIsNowhere() {
    let stacked = DropGrid([[1], [2, 3]])
    #expect(stacked.target(dragging: 1, at: 160, 200) == .nowhere)
  }

  @Test func droppingALoneColumnOnItsOwnSlotIsNowhere() {
    #expect(row.target(dragging: 1, at: 105, 200) == .nowhere)
    #expect(row.target(dragging: 2, at: 105, 200) == .nowhere)
    #expect(row.target(dragging: 2, at: 215, 200) == .nowhere)
    #expect(row.target(dragging: 1, at: 115, 200) == .nowhere)
  }

  @Test func draggingTheOnlyWindowIsNowhere() {
    let single = DropGrid([[1]])
    for x in [-20.0, 5, 50, 95, 105, 300] {
      #expect(single.target(dragging: 1, at: x, 200) == .nowhere)
    }
  }

  @Test func droppingBesideAColumnMovesTheWindowThere() {
    #expect(row.columns(afterDropping: 1, at: 315, 200) == [[2], [3], [1]])
    #expect(row.columns(afterDropping: 3, at: 5, 200) == [[3], [1], [2]])
    #expect(row.columns(afterDropping: 1, at: 215, 200) == [[2], [1], [3]])
  }

  @Test func droppingOnTheMiddleStacksIntoThatColumn() {
    #expect(row.columns(afterDropping: 1, at: 270, 100) == [[2], [1, 3]])
    #expect(row.columns(afterDropping: 1, at: 270, 300) == [[2], [3, 1]])
  }

  @Test func pullingOutOfAStackToTheLeft() {
    let stack = DropGrid([[1, 2], [3]])
    #expect(stack.target(dragging: 2, at: 10, 100) == .column(position: 0))
    #expect(stack.columns(afterDropping: 2, at: 10, 100) == [[2], [1], [3]])
  }

  @Test func pullingOutOfAStackToTheRight() {
    let stack = DropGrid([[1, 2], [3]])
    #expect(stack.target(dragging: 2, at: 90, 100) == .column(position: 1))
    #expect(stack.columns(afterDropping: 2, at: 90, 100) == [[1], [2], [3]])
  }

  @Test func pullingTheFirstRowOutIntoTheGapBesideTheStack() {
    let stack = DropGrid([[1, 2], [3]])
    #expect(stack.columns(afterDropping: 1, at: 105, 100) == [[2], [1], [3]])
  }

  @Test func droppingIntoAnotherStackAtEachRowPosition() {
    let stack = DropGrid([[1], [2, 3, 4]])
    let rows = stack.layout.placements.filter { $0.column == 1 }.map(\.frame)
    let positions: [(row: Int, y: Double, expected: [UInt32])] = [
      (0, rows[0].minY + 5, [1, 2, 3, 4]),
      (0, rows[0].maxY - 5, [2, 1, 3, 4]),
      (1, rows[1].minY + 5, [2, 1, 3, 4]),
      (1, rows[1].maxY - 5, [2, 3, 1, 4]),
      (2, rows[2].minY + 5, [2, 3, 1, 4]),
      (2, rows[2].maxY - 5, [2, 3, 4, 1]),
    ]
    for position in positions {
      let result = stack.columns(afterDropping: 1, at: 160, position.y)
      #expect(result == [position.expected])
    }
  }

  @Test func droppingOnAWindowOfTheSameStackReordersIt() {
    let stack = DropGrid([[1, 2, 3]])
    let rows = stack.layout.placements.map(\.frame)
    #expect(stack.columns(afterDropping: 1, at: 50, rows[2].maxY - 5) == [[2, 3, 1]])
    #expect(stack.columns(afterDropping: 3, at: 50, rows[0].minY + 5) == [[3, 1, 2]])
    #expect(stack.columns(afterDropping: 1, at: 50, rows[1].maxY - 5) == [[2, 1, 3]])
  }

  @Test func droppingAStackedWindowOnItsCurrentRowPositionIsNowhere() {
    let stack = DropGrid([[1, 2, 3]])
    let rows = stack.layout.placements.map(\.frame)
    #expect(stack.target(dragging: 2, at: 50, rows[0].maxY - 5) == .nowhere)
    #expect(stack.target(dragging: 2, at: 50, rows[2].minY + 5) == .nowhere)
    #expect(stack.target(dragging: 1, at: 50, rows[1].minY + 5) == .nowhere)
    #expect(stack.target(dragging: 3, at: 50, rows[1].maxY - 5) == .nowhere)
  }

  @Test func theDraggedWindowsOwnFrameIsNeverATarget() {
    #expect(row.target(dragging: 2, at: 160, 100) == .nowhere)
  }
}
