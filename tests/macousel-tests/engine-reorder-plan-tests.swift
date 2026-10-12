import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineReorderPlanTests {
  private func columns(_ rows: [[UInt32]]) -> [[WindowID]] {
    rows.map { $0.map { WindowID($0) } }
  }

  private func plan(
    _ rows: [[UInt32]], moving window: UInt32, to target: DropTarget
  ) -> EngineReorderPlan? {
    EngineReorderPlan(columns: columns(rows), moving: WindowID(window), to: target)
  }

  @Test func nowhereAndUnknownWindowsHaveNoPlan() {
    #expect(plan([[1], [2]], moving: 1, to: .nowhere) == nil)
    #expect(plan([[1], [2]], moving: 9, to: .column(position: 0)) == nil)
    #expect(plan([[1], [2]], moving: 1, to: .stack(onto: WindowID(9), side: .above)) == nil)
    #expect(plan([[1], [2]], moving: 1, to: .stack(onto: WindowID(1), side: .above)) == nil)
  }

  @Test func recordsTheSourceColumnAndRow() {
    let found = plan([[1], [2, 3]], moving: 3, to: .column(position: 0))

    #expect(found?.source == EngineColumns.Position(column: 1, row: 1))
  }

  @Test func positionCountsTheColumnsWithoutTheDraggedWindow() {
    let toEnd = plan([[1], [2], [3]], moving: 1, to: .column(position: 2))
    let pastEnd = plan([[1], [2], [3]], moving: 1, to: .column(position: 9))
    let toStart = plan([[1], [2], [3]], moving: 3, to: .column(position: 0))
    let oneRight = plan([[1], [2], [3]], moving: 1, to: .column(position: 1))

    #expect(toEnd?.steps == [.moveColumn(to: 2)])
    #expect(pastEnd?.steps == [.moveColumn(to: 2)])
    #expect(toStart?.steps == [.moveColumn(to: 0)])
    #expect(oneRight?.steps == [.moveColumn(to: 1)])
  }

  @Test func droppingAloneWindowAtItsOwnSlotChangesNothing() {
    #expect(plan([[1], [2], [3]], moving: 2, to: .column(position: 1))?.steps == [])
    #expect(plan([[1], [2], [3]], moving: 3, to: .column(position: 2))?.steps == [])
  }

  @Test func leavingAStackUnstacksFirst() {
    let beyond = plan([[1], [2, 3], [4]], moving: 3, to: .column(position: 3))
    let inPlace = plan([[1], [2, 3], [4]], moving: 3, to: .column(position: 2))
    let before = plan([[1], [2, 3], [4]], moving: 2, to: .column(position: 0))

    #expect(beyond?.steps == [.unstack, .moveColumn(to: 3)])
    #expect(inPlace?.steps == [.unstack])
    #expect(before?.steps == [.unstack, .moveColumn(to: 0)])
  }

  @Test func stackingOntoAColumnToTheLeftMovesNothing() {
    let found = plan([[1], [2]], moving: 2, to: .stack(onto: WindowID(1), side: .below))

    #expect(found?.steps == [.stack(onto: WindowID(1))])
  }

  @Test func stackingAboveRaisesTheWindowToTheTargetRow() {
    let found = plan([[1, 2], [3]], moving: 3, to: .stack(onto: WindowID(1), side: .above))

    #expect(found?.steps == [.stack(onto: WindowID(1)), .moveRow(by: -2)])
  }

  @Test func stackingBelowAMiddleRowRaisesByOne() {
    let found = plan([[1, 2, 3], [4]], moving: 4, to: .stack(onto: WindowID(2), side: .below))

    #expect(found?.steps == [.stack(onto: WindowID(2)), .moveRow(by: -1)])
  }

  @Test func stackingFromTheLeftMovesPastTheTarget() {
    let found = plan([[1], [2], [3]], moving: 1, to: .stack(onto: WindowID(3), side: .below))

    #expect(found?.steps == [.moveColumn(to: 2), .stack(onto: WindowID(3))])
  }

  @Test func stackingFromTheRightMovesNextToTheTarget() {
    let found = plan([[1], [2], [3], [4]], moving: 4, to: .stack(onto: WindowID(1), side: .below))

    #expect(found?.steps == [.moveColumn(to: 1), .stack(onto: WindowID(1))])
  }

  @Test func stackingFromInsideAStackUnstacksFirst() {
    let found = plan([[1], [2, 3], [4]], moving: 3, to: .stack(onto: WindowID(4), side: .below))

    #expect(found?.steps == [.unstack, .moveColumn(to: 3), .stack(onto: WindowID(4))])
  }

  @Test func reorderingInsideAStackMovesRows() {
    let up = plan([[1, 2, 3]], moving: 3, to: .stack(onto: WindowID(1), side: .above))
    let down = plan([[1, 2, 3]], moving: 1, to: .stack(onto: WindowID(3), side: .below))
    let beside = plan([[1, 2, 3]], moving: 1, to: .stack(onto: WindowID(3), side: .above))

    #expect(up?.steps == [.moveRow(by: -2)])
    #expect(down?.steps == [.moveRow(by: 2)])
    #expect(beside?.steps == [.moveRow(by: 1)])
  }

  @Test func droppingWhereTheWindowAlreadySitsInAStackChangesNothing() {
    let below = plan([[1, 2]], moving: 2, to: .stack(onto: WindowID(1), side: .below))
    let above = plan([[1, 2]], moving: 1, to: .stack(onto: WindowID(2), side: .above))

    #expect(below?.steps == [])
    #expect(above?.steps == [])
  }

  @Test func shiftingMovesTheColumnOneStep() {
    let right = EngineReorderPlan(columns: columns([[1], [2, 3], [4]]), moving: WindowID(3), shifting: .right)
    let edge = EngineReorderPlan(columns: columns([[1], [2]]), moving: WindowID(1), shifting: .left)

    #expect(right?.steps == [.moveColumn(to: 2)])
    #expect(edge == nil)
  }

  @Test func keysMapToTheBuiltInMoves() {
    let layout = EngineColumns(FakePaneruStrip(columns: [[1], [2, 3], [4]]).snapshot.tiledWindows)

    #expect(EngineKeyMove(key: .moveWindow(.left), window: WindowID(4), columns: layout) == .shift(.left))
    #expect(
      EngineKeyMove(key: .moveWindow(.up), window: WindowID(3), columns: layout)
        == .drop(.stack(onto: WindowID(2), side: .above)))
    #expect(
      EngineKeyMove(key: .moveWindow(.down), window: WindowID(2), columns: layout)
        == .drop(.stack(onto: WindowID(3), side: .below)))
    #expect(EngineKeyMove(key: .moveWindow(.up), window: WindowID(2), columns: layout) == nil)
    #expect(
      EngineKeyMove(key: .moveWindowToPlace(1), window: WindowID(4), columns: layout)
        == .drop(.column(position: 0)))
    #expect(
      EngineKeyMove(key: .moveWindowToPlace(9), window: WindowID(1), columns: layout)
        == .drop(.column(position: 3)))
    #expect(EngineKeyMove(key: .moveWindowToPlace(5), window: WindowID(1), columns: layout) == nil)
    #expect(EngineKeyMove(key: .moveWindowToPlace(4), window: WindowID(3), columns: layout) != nil)
    #expect(EngineKeyMove(key: .confirm, window: WindowID(1), columns: layout) == nil)
  }
}
