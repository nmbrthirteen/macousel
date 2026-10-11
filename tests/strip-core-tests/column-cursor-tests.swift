import Testing

@testable import StripCore

struct ColumnCursorTests {
  private let columns: [[WindowID]] = [[id(1)], [id(2), id(3), id(4)], [id(5), id(6)], [id(7)]]

  private func cursor(selecting window: UInt32) -> ColumnCursor {
    ColumnCursor(columns: columns, selecting: id(window))
  }

  @Test func startsOnTheRequestedWindow() {
    let start = cursor(selecting: 6)
    #expect(start.window == id(6))
    #expect(start.column == 2)
    #expect(start.row == 1)
  }

  @Test func startsOnTheFirstWindowWhenTheRequestedOneIsMissing() {
    #expect(ColumnCursor(columns: columns, selecting: id(99)).window == id(1))
    #expect(ColumnCursor(columns: columns).window == id(1))
  }

  @Test func emptyColumnsAreDropped() {
    let start = ColumnCursor(columns: [[], [id(1)], []], selecting: id(1))
    #expect(start.columns == [[id(1)]])
    #expect(start.window == id(1))
  }

  @Test func rightMovesToTheNextColumn() {
    var moving = cursor(selecting: 1)
    let moved = moving.move(.right)
    #expect(moved)
    #expect(moving.window == id(2))
  }

  @Test func leftMovesToThePreviousColumn() {
    var moving = cursor(selecting: 5)
    let moved = moving.move(.left)
    #expect(moved)
    #expect(moving.window == id(2))
  }

  @Test func downAndUpMoveWithinTheColumn() {
    var moving = cursor(selecting: 2)
    let down = moving.move(.down)
    #expect(down)
    #expect(moving.window == id(3))
    let up = moving.move(.up)
    #expect(up)
    #expect(moving.window == id(2))
  }

  @Test func rowIsKeptWhenTheNextColumnIsTallEnough() {
    var moving = cursor(selecting: 3)
    let moved = moving.move(.right)
    #expect(moved)
    #expect(moving.window == id(6))
  }

  @Test func rowIsClampedWhenTheNextColumnIsShorter() {
    var moving = cursor(selecting: 4)
    let moved = moving.move(.right)
    #expect(moved)
    #expect(moving.window == id(6))
    #expect(moving.row == 1)
  }

  @Test func rowIsClampedWhenMovingIntoASingleWindowColumn() {
    var moving = cursor(selecting: 6)
    let moved = moving.move(.right)
    #expect(moved)
    #expect(moving.window == id(7))
    #expect(moving.row == 0)
  }

  private static let edgeMoves: [(UInt32, Direction)] = [
    (1, .left), (1, .up), (1, .down), (7, .right), (2, .up), (4, .down),
  ]

  @Test(arguments: edgeMoves)
  func movingPastAnEdgeChangesNothing(start: UInt32, direction: Direction) {
    var moving = cursor(selecting: start)
    let before = moving
    let moved = moving.move(direction)
    #expect(!moved)
    #expect(moving == before)
  }

  @Test func jumpSelectsTheNumberedColumn() {
    var moving = cursor(selecting: 1)
    let moved = moving.jump(toPlace: 3)
    #expect(moved)
    #expect(moving.window == id(5))
  }

  @Test func jumpKeepsTheRowWhereItFits() {
    var moving = cursor(selecting: 3)
    let moved = moving.jump(toPlace: 3)
    #expect(moved)
    #expect(moving.window == id(6))
  }

  @Test func jumpToNineSelectsTheLastColumn() {
    var moving = cursor(selecting: 3)
    let moved = moving.jump(toPlace: 9)
    #expect(moved)
    #expect(moving.window == id(7))
  }

  @Test func jumpToAColumnThatDoesNotExistChangesNothing() {
    var moving = cursor(selecting: 3)
    let before = moving
    let moved = moving.jump(toPlace: 5)
    #expect(!moved)
    #expect(moving == before)
  }

  @Test func jumpToTheCurrentColumnChangesNothing() {
    var moving = cursor(selecting: 3)
    let moved = moving.jump(toPlace: 2)
    #expect(!moved)
    #expect(moving.window == id(3))
  }

  @Test(arguments: [0, 10, -1])
  func jumpOutsideOneToNineChangesNothing(place: Int) {
    var moving = cursor(selecting: 1)
    let moved = moving.jump(toPlace: place)
    #expect(!moved)
    #expect(moving.window == id(1))
  }

  @Test func emptyInputSelectsNothingAndIgnoresEveryCommand() {
    var empty = ColumnCursor(columns: [])
    #expect(empty.window == nil)
    for direction in Direction.allCases {
      let moved = empty.move(direction)
      #expect(!moved)
    }
    let jumped = empty.jump(toPlace: 9)
    #expect(!jumped)
    #expect(empty.window == nil)
  }
}
