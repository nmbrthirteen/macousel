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

  @Test func differentWidthsAtTheSameXStaySeparate() {
    let columns = EngineColumns([window(1, x: 0, width: 100), window(2, x: 0, y: 500, width: 80)])

    #expect(ids(columns) == [[1], [2]])
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

  @Test func cyclesToTheColumnHoldingAnAppWindow() {
    var mail = window(3, x: 100, y: 500)
    mail.bundleId = "mail"
    var focused = window(1, x: 0)
    focused.focused = true
    let snapshot = EngineFixtures.snapshot(of: [focused, window(2, x: 100), mail])

    #expect(EngineAppCycler.choice(bundleIdentifier: "mail", in: snapshot) == .focusColumn(2))
  }
}
