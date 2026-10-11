import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct StructureCommandTests {
  private func launchedRow(_ count: CGWindowID = 3) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(count)
    fixture.launch()
    return (fixture, row)
  }

  private func expectedRow(_ columns: [CGWindowID]) -> ExpectedStrip {
    ExpectedStrip(columns: columns, fraction: 0.25)
  }

  @Test func moveRightSwapsTheFocusedColumnWithItsNeighbour() throws {
    let (fixture, row) = try launchedRow()

    fixture.manager.perform(.moveRight)

    var expected = expectedRow([1, 2, 3])
    expected.apply { $0.moveFocused(.right) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.layout.placements.map(\.window.rawValue) == [2, 1, 3])
  }

  @Test func cycleWidthStepsToTheNextPresetWidth() throws {
    let (fixture, row) = try launchedRow()

    fixture.manager.perform(.cycleWidth)

    var expected = expectedRow([1, 2, 3])
    let config = expected.config
    expected.apply { $0.cycleWidth(config: config) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(try #require(row[0].frame).width > 240)
  }

  @Test func stackLeftPutsTheFocusedWindowUnderItsLeftNeighbour() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.focusRight)

    fixture.manager.perform(.stackLeft)

    var expected = expectedRow([1, 2, 3])
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(try #require(row[0].frame).minX == (try #require(row[1].frame).minX))
  }

  @Test func popOutRightTurnsAStackedWindowBackIntoAColumn() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)

    fixture.manager.perform(.popOutRight)

    #expect(fixture.frames(of: row) == expectedRowAfterPopOut().frames)
  }

  private func expectedRowAfterPopOut() -> ExpectedStrip {
    var expected = expectedRow([1, 2, 3])
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.apply { $0.popOutFocused(to: .right) }
    return expected
  }

  @Test func toggleTabbedStacksTheColumnBehindOneTabBar() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)

    fixture.manager.perform(.toggleTabbed)

    var expected = expectedRow([1, 2, 3])
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.apply { $0.toggleTabbed() }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(row[0].frame == row[1].frame)
    let bar = try #require(fixture.overlays.tabBars.first)
    #expect(fixture.overlays.tabBars.count == 1)
    #expect(bar.tabs.map(\.title) == ["Window 1", "Window 2"])
    #expect(bar.tabs.map(\.isActive) == [false, true])
  }

  @Test func tabbedColumnBecomesAStackAgainWhenToggledTwice() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    let stacked = fixture.frames(of: row)

    fixture.manager.perform(.toggleTabbed)
    fixture.manager.perform(.toggleTabbed)

    #expect(fixture.frames(of: row) == stacked)
    #expect(fixture.overlays.tabBars.isEmpty)
  }

  @Test func tallerGrowsTheFocusedRowOfAStack() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    let before = try #require(row[1].frame).height

    fixture.manager.perform(.taller)

    var expected = expectedRow([1, 2, 3])
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    let step = expected.config.heightStep
    expected.apply { $0.adjustHeight(by: step) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(try #require(row[1].frame).height > before)
  }

  @Test func toggleFullWidthGivesTheColumnTheWholeViewport() throws {
    let (fixture, row) = try launchedRow()

    fixture.manager.perform(.toggleFullWidth)

    var expected = expectedRow([1, 2, 3])
    expected.apply { $0.toggleFullWidth() }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(try #require(row[0].frame).width == fixture.display.visibleFrame.width - 16)
  }
}
