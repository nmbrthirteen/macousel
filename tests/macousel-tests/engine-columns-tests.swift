import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineColumnsTests {
  private func window(
    _ id: Int32, x: Int, y: Int = 0, width: Int = 100, height: Int = 500, floating: Bool = false
  ) -> EngineWindow {
    EngineWindow(
      windowId: id, floating: floating, displayId: 1,
      frame: EngineWindow.Frame(x: x, y: y, width: width, height: height))
  }

  private func ids(_ columns: EngineColumns) -> [[UInt32]] {
    columns.windowIDs.map { $0.map(\.rawValue) }
  }

  @Test func eachSingleWindowIsItsOwnColumn() {
    let columns = EngineColumns([window(1, x: 0), window(2, x: 100), window(3, x: 200)])

    #expect(ids(columns) == [[1], [2], [3]])
  }

  @Test func consecutiveWindowsAtTheSameXAndWidthFormAStack() {
    let columns = EngineColumns([
      window(1, x: 0), window(2, x: 100, y: 0), window(3, x: 100, y: 500), window(4, x: 200),
    ])

    #expect(ids(columns) == [[1], [2, 3], [4]])
  }

  @Test func threeWindowsStackIntoOneColumn() {
    let columns = EngineColumns([
      window(1, x: 0, y: 0, height: 100), window(2, x: 0, y: 100, height: 200),
      window(3, x: 0, y: 300, height: 300),
    ])

    #expect(ids(columns) == [[1, 2, 3]])
  }

  @Test func aStackWhoseMembersReportDifferentWidthsStaysOneColumn() {
    let columns = EngineColumns([window(1, x: 0, width: 100), window(2, x: 0, y: 500, width: 80)])

    #expect(ids(columns) == [[1, 2]])
  }

  @Test func aSubPixelDifferenceInXStillStacks() {
    let columns = EngineColumns([window(1, x: 0), window(2, x: 1, y: 500)])

    #expect(ids(columns) == [[1, 2]])
  }

  @Test func windowsTwoPixelsApartInXAreSeparateColumns() {
    let columns = EngineColumns([window(1, x: 0), window(2, x: 2, y: 500)])

    #expect(ids(columns) == [[1], [2]])
  }

  @Test func aGapInsideTheTolerancePreservesTheStack() {
    let gap = EngineColumns([window(1, x: 0), window(2, x: 0, y: 508)])
    let overlap = EngineColumns([window(1, x: 0), window(2, x: 0, y: 480)])

    #expect(ids(gap) == [[1, 2]])
    #expect(ids(overlap) == [[1, 2]])
  }

  @Test func aWindowStartingTooFarAboveTheBottomStartsANewColumn() {
    let columns = EngineColumns([window(1, x: 0), window(2, x: 0, y: 470)])

    #expect(ids(columns) == [[1], [2]])
  }

  @Test func aParkedStackFollowedByAParkedSingleKeepsTwoColumns() {
    let strip = FakePaneruStrip(columns: [[1, 2], [3], [4], [5]])
    strip.viewport = 2000...2900

    #expect(ids(strip.snapshot.tiledColumns) == [[1, 2], [3], [4], [5]])
  }

  @Test func twoParkedStacksInARowKeepTwoColumns() {
    let left = FakePaneruStrip(columns: [[1, 2], [3, 4], [5]])
    left.viewport = 2000...2900
    let right = FakePaneruStrip(columns: [[1], [2], [3, 4], [5, 6]])
    right.viewport = 0...1000

    #expect(ids(left.snapshot.tiledColumns) == [[1, 2], [3, 4], [5]])
    #expect(ids(right.snapshot.tiledColumns) == [[1], [2], [3, 4], [5, 6]])
  }

  @Test func parkedSinglesShareOneXAndStaySeparate() {
    let strip = FakePaneruStrip(columns: [[1], [2], [3], [4]])
    strip.viewport = 2000...2900

    #expect(ids(strip.snapshot.tiledColumns) == [[1], [2], [3], [4]])
  }

  @Test func measuresWhetherAColumnIsOnScreenByItsOverlap() {
    let viewport = CGRect(x: 1000, y: 0, width: 1000, height: 800)
    let sliver = EngineColumns([window(1, x: 49, width: 960)]).columns[0]
    let edge = EngineColumns([window(1, x: 1952, width: 960)]).columns[0]
    let inside = EngineColumns([window(1, x: 1500, width: 960)]).columns[0]
    let unframed = EngineColumns([EngineWindow(windowId: 1, displayId: 1)]).columns[0]

    #expect(!sliver.isOnScreen(in: viewport))
    #expect(edge.isOnScreen(in: viewport))
    #expect(inside.isOnScreen(in: viewport))
    #expect(!unframed.isOnScreen(in: viewport))
  }

  @Test func aColumnParkedBelowTheViewportIsOffScreen() {
    let viewport = CGRect(x: 1000, y: 0, width: 1000, height: 800)
    let parked = EngineColumns([window(1, x: 1000, y: 790, width: 960)]).columns[0]

    #expect(!parked.isOnScreen(in: viewport))
  }

  @Test func equalFramesAtTheSameYStaySeparate() {
    let columns = EngineColumns([window(1, x: 0), window(2, x: 0)])

    #expect(ids(columns) == [[1], [2]])
  }

  @Test func aWindowWithoutAFrameStartsItsOwnColumn() {
    let missing = EngineWindow(windowId: 2, displayId: 1)
    let columns = EngineColumns([window(1, x: 0), missing, window(3, x: 0, y: 500)])

    #expect(ids(columns) == [[1], [2], [3]])
  }

  @Test func floatingWindowsAreLeftOutOfTheSnapshotColumns() {
    let snapshot = EngineFixtures.snapshot(of: [
      window(1, x: 0), window(2, x: 100, floating: true), window(3, x: 200),
    ])

    #expect(snapshot.tiledColumns.windowIDs.map { $0.map(\.rawValue) } == [[1], [3]])
  }

  @Test func findsTheColumnAndRowOfAWindow() {
    let columns = EngineColumns([window(1, x: 0), window(2, x: 100), window(3, x: 100, y: 500)])

    #expect(columns.columnIndex(of: WindowID(3)) == 1)
    #expect(columns.row(of: WindowID(3)) == 1)
    #expect(columns.row(of: WindowID(1)) == 0)
    #expect(columns.columnIndex(of: WindowID(9)) == nil)
  }

  @Test func sharesHeightByFrameHeightInsideAColumn() throws {
    let columns = EngineColumns([
      window(1, x: 0, y: 0, height: 100), window(2, x: 0, y: 100, height: 300),
    ])

    let shares = try #require(columns.columns.first).heightShares

    #expect(shares == [0.25, 0.75])
  }

  @Test func countsStackedWindowsInTheFocusedColumn() throws {
    var focused = window(2, x: 100, y: 0)
    focused.focused = true
    let snapshot = EngineFixtures.snapshot(of: [window(1, x: 0), focused, window(3, x: 100, y: 500)])

    let position = try #require(snapshot.stripPosition)

    #expect(position.columnCount == 2)
    #expect(position.focusedIndex == 1)
    #expect(position.windowsInFocusedColumn == 2)
  }

  @Test func focusesTheColumnOfAFocusedRowBelowTheTop() {
    var focused = window(3, x: 100, y: 500)
    focused.focused = true
    let snapshot = EngineFixtures.snapshot(of: [window(1, x: 0), window(2, x: 100), focused])

    #expect(snapshot.focusedColumnIndex == 1)
    #expect(snapshot.focusedWindowID == WindowID(3))
  }

  @Test func cyclesToAnAppWindowLowerInAStack() {
    var mail = window(3, x: 100, y: 500)
    mail.bundleId = "mail"
    var focused = window(1, x: 0)
    focused.focused = true
    let snapshot = EngineFixtures.snapshot(of: [focused, window(2, x: 100), mail])

    #expect(EngineAppCycler.choice(bundleIdentifier: "mail", in: snapshot) == .focusWindow(WindowID(3)))
  }
}
