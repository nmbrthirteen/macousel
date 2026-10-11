import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct OverviewEditTests {
  private func openedOverview(
    _ count: CGWindowID = 3
  ) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(count)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)
    return (fixture, row)
  }

  private func expectedRow(
    count: CGWindowID = 3, _ change: (inout Strip) -> Void
  ) -> ExpectedStrip {
    var expected = ExpectedStrip(columns: Array(1...count), fraction: 0.25)
    expected.apply(change)
    return expected
  }

  private func windows(_ fixture: ControllerFixture) -> [[UInt32]] {
    OverviewSnapshots.windows(fixture.overlays.overview?.snapshot ?? .empty)
  }

  @Test func droppingACardAtAColumnPositionMovesItThereAndKeepsTheOverviewOpen() throws {
    let (fixture, row) = try openedOverview()

    fixture.overlays.drop(WindowID(1), as: .column(position: 2))

    let expected = expectedRow {
      $0.move(WindowID(1), toColumn: 2)
      $0.focus(WindowID(1))
    }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(windows(fixture) == [[2], [3], [1]])
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(1))
  }

  @Test func droppingAboveAndBelowAnotherCardStacksIt() throws {
    let (above, aboveRow) = try openedOverview()
    above.overlays.drop(WindowID(1), as: .stack(onto: WindowID(3), side: .above))
    let (below, belowRow) = try openedOverview()
    below.overlays.drop(WindowID(1), as: .stack(onto: WindowID(3), side: .below))

    let expectedAbove = expectedRow {
      $0.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 0)
      $0.focus(WindowID(1))
    }
    let expectedBelow = expectedRow {
      $0.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 1)
      $0.focus(WindowID(1))
    }
    #expect(above.frames(of: aboveRow) == expectedAbove.frames)
    #expect(below.frames(of: belowRow) == expectedBelow.frames)
    #expect(windows(above) == [[2], [1, 3]])
    #expect(windows(below) == [[2], [3, 1]])
    #expect(above.overlays.overview?.snapshot.selection == WindowID(1))
  }

  @Test func droppingBesideItsOwnStackPullsTheWindowOut() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleOverview)
    #expect(windows(fixture) == [[1, 2], [3]])

    fixture.overlays.drop(WindowID(2), as: .column(position: 1))

    #expect(windows(fixture) == [[1], [2], [3]])
    #expect(fixture.overlays.overview != nil)
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(2))
    #expect(row.allSatisfy { fixture.display.visibleFrame.intersects($0.frame ?? .zero) })
  }

  @Test func theFocusedWindowStaysFocusedAfterAnEdit() throws {
    let (fixture, row) = try openedOverview()
    fixture.overlays.press(.jump(3))

    fixture.overlays.drop(WindowID(1), as: .column(position: 2))

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply {
      $0.move(WindowID(1), toColumn: 2)
      $0.focus(WindowID(1))
    }
    #expect(fixture.frames(of: row) == expected.frames)
    fixture.overlays.press(.dismiss)
    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func settingAColumnWidthResizesTheRealWindows() throws {
    let (fixture, row) = try openedOverview()

    fixture.overlays.setColumnWidth(of: WindowID(2), to: 0.75)

    let expected = expectedRow {
      $0.setWidthFraction(0.75, ofColumnContaining: WindowID(2))
      $0.focus(WindowID(1))
    }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(fixture.overlays.overview?.snapshot.columns[1].width == Double(try #require(row[1].frame).width))
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(2))
  }

  @Test(arguments: [(0.02, 0.1), (3.0, 1.0)] as [(Double, Double)])
  func columnWidthsAreClamped(requested: Double, stored: Double) throws {
    let (fixture, row) = try openedOverview()

    fixture.overlays.setColumnWidth(of: WindowID(2), to: requested)

    let expected = expectedRow {
      $0.setWidthFraction(stored, ofColumnContaining: WindowID(2))
      $0.focus(WindowID(1))
    }
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func settingARowHeightMovesHeightBetweenTheTwoRows() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleOverview)

    fixture.overlays.setRowHeight(of: WindowID(1), to: 0.7, borrowingFrom: .below)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    let config = expected.config
    let viewport = expected.display.visibleFrame.height
    let rowsHeight = viewport - 2 * config.outerGap - config.innerGap
    expected.apply {
      $0.setHeight(
        0.7 * rowsHeight, of: WindowID(1), borrowingFrom: .below, viewportHeight: viewport,
        config: config)
    }
    #expect(fixture.frames(of: row) == expected.frames)
    let upper = try #require(row[0].frame).height
    let lower = try #require(row[1].frame).height
    #expect(upper > lower)
    let shares = try #require(fixture.overlays.overview).snapshot.columns[0].cards.map(\.heightShare)
    #expect(abs(shares[0] - 0.7) < 0.01)
  }

  @Test func rowHeightsStopAtTheMinimumShare() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleOverview)

    fixture.overlays.setRowHeight(of: WindowID(1), to: 0.99, borrowingFrom: .below)

    let lower = try #require(row[1].frame).height
    let upper = try #require(row[0].frame).height
    #expect(abs(lower / (upper + lower) - Column.minimumHeightShare) < 0.01)
  }

  @Test func shiftArrowsMoveTheSelectedWindow() throws {
    let (fixture, row) = try openedOverview()

    fixture.overlays.press(.moveWindow(.right))

    let expected = expectedRow {
      $0.focus(WindowID(1))
      $0.moveFocused(.right)
    }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(windows(fixture) == [[2], [1], [3]])
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(1))
  }

  @Test func shiftUpAndDownReorderWithinAStack() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    _ = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleOverview)

    fixture.overlays.press(.moveWindow(.up))

    #expect(windows(fixture) == [[2, 1], [3]])
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(2))
  }

  @Test func widenAndNarrowUseTheConfiguredStep() throws {
    let (fixture, row) = try openedOverview()

    fixture.overlays.press(.widen)
    let widened = expectedRow {
      $0.focus(WindowID(1))
      $0.adjustWidth(by: 0.05, viewportWidth: 1000, config: LayoutConfig())
    }
    #expect(fixture.frames(of: row) == widened.frames)

    fixture.overlays.press(.narrow)
    fixture.overlays.press(.narrow)
    let narrowed = expectedRow {
      $0.focus(WindowID(1))
      $0.adjustWidth(by: -0.05, viewportWidth: 1000, config: LayoutConfig())
    }
    #expect(fixture.frames(of: row) == narrowed.frames)
    #expect(fixture.overlays.overview != nil)
  }

  @Test func shiftDigitMovesTheLastWindowToSecondPlace() throws {
    let (fixture, row) = try openedOverview()
    fixture.overlays.press(.jump(3))
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(3))

    fixture.overlays.press(.moveWindowToPlace(2))

    let expected = expectedRow {
      $0.focus(WindowID(3))
      $0.moveFocused(.left)
      $0.focus(WindowID(1))
    }
    #expect(windows(fixture) == [[1], [3], [2]])
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(3))
    #expect(fixture.overlays.overview != nil)
  }

  @Test func shiftDigitTakesAStackedWindowOutOfItsStack() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    _ = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleOverview)

    fixture.overlays.press(.moveWindowToPlace(2))

    #expect(windows(fixture) == [[1], [2], [3]])
    #expect(fixture.overlays.overview?.snapshot.selection == WindowID(2))
  }

  @Test func shiftNineMovesTheWindowToTheEnd() throws {
    let (fixture, _) = try openedOverview()

    fixture.overlays.press(.moveWindowToPlace(9))

    #expect(windows(fixture) == [[2], [3], [1]])
  }

  @Test func aPlaceBeyondTheColumnCountChangesNothing() throws {
    let (fixture, row) = try openedOverview()
    let before = fixture.frames(of: row)

    fixture.overlays.press(.moveWindowToPlace(7))

    #expect(fixture.frames(of: row) == before)
    #expect(windows(fixture) == [[1], [2], [3]])
  }

  @Test func editsAfterClosingAreIgnored() throws {
    let (fixture, row) = try openedOverview()
    fixture.overlays.press(.dismiss)
    let before = fixture.frames(of: row)

    fixture.overlays.drop(WindowID(1), as: .column(position: 2))
    fixture.overlays.setColumnWidth(of: WindowID(1), to: 0.9)

    #expect(fixture.frames(of: row) == before)
  }

  @Test func aClickOnACardStillFocusesItAndClosesTheOverview() throws {
    let (fixture, row) = try openedOverview()

    fixture.overlays.click(WindowID(3))

    #expect(fixture.overlays.overview == nil)
    #expect(row[2].focusCount == 1)
  }
}
