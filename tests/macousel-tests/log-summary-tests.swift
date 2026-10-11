import StripCore
import Testing

@testable import Macousel

@MainActor
struct LogSummaryTests {
  @Test func shapeListsTheWindowsPerColumn() {
    var built = Strip()
    for id in 1...4 as ClosedRange<UInt32> { built.append(WindowID(id), width: .fraction(0.5)) }
    built.stack(WindowID(2), ontoColumnOf: WindowID(1), atRow: 1)
    built.stack(WindowID(3), ontoColumnOf: WindowID(1), atRow: 2)
    #expect(built.shapeSummary == "3,1")
  }

  @Test func shapeOfAnEmptyStripSaysEmpty() {
    #expect(Strip().shapeSummary == "empty")
    #expect(Strip().focusSummary == "none")
  }

  @Test func plainColumnsAreAllOnes() {
    var built = Strip()
    for id in 1...3 as ClosedRange<UInt32> { built.append(WindowID(id), width: .fraction(0.5)) }
    #expect(built.shapeSummary == "1,1,1")
    #expect(built.focusSummary == "0")
    built.focusLast()
    #expect(built.focusSummary == "2")
  }

  @Test func outcomesHaveReadableNames() {
    #expect(StripCommandOutcome.applied.logName == "applied")
    #expect(StripCommandOutcome.appliedKeepingScroll.logName == "applied keeping scroll")
    #expect(StripCommandOutcome.blockedAtEdge(.left).logName == "blocked at left edge")
    #expect(StripCommandOutcome.blockedAtEdge(.right).logName == "blocked at right edge")
    #expect(StripCommandOutcome.ignored.logName == "ignored")
  }

  @Test func dragBranchesHaveReadableNames() {
    #expect(DragBranch.resizedWidth.logName == "resized width")
    #expect(DragBranch.resizedHeight.logName == "resized height")
    #expect(DragBranch.stacked(above: true).logName == "stacked above a target")
    #expect(DragBranch.stacked(above: false).logName == "stacked below a target")
    #expect(DragBranch.reordered(column: 3).logName == "reordered to column 3")
    #expect(DragBranch.movedToDisplay.logName == "moved to another display")
  }

  @Test func onlyDropsThatDidNotStackReportThePointerPosition() {
    #expect(DragBranch.reordered(column: 1).reportsPointerPosition)
    #expect(DragBranch.movedToDisplay.reportsPointerPosition)
    #expect(!DragBranch.stacked(above: true).reportsPointerPosition)
    #expect(!DragBranch.resizedWidth.reportsPointerPosition)
  }
}
