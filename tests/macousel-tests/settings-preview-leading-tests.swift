import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct SettingsPreviewLeadingTests {
  private let half = ColumnWidth.fraction(0.5)

  private func base() -> StripPreviewScenario {
    StripPreviewScenario(columnWidths: [half, half, half], stackedColumn: 1, focusTrail: [1, 2])
  }

  @Test func leadingColumnsShiftEveryIndex() {
    let shifted = base().withLeadingColumns(2, width: half)
    #expect(shifted.columnWidths.count == 5)
    #expect(shifted.focusTrail == [3, 4])
    #expect(shifted.stackedColumn == 3)
  }

  @Test func zeroLeadingColumnsLeaveTheScenarioUnchanged() {
    #expect(base().withLeadingColumns(0, width: half) == base())
  }

  @Test func narrowerColumnsNeedMoreLeadingColumns() {
    #expect(StripPreviewScenario.leadingColumnCount(forWidth: 1) == 1)
    #expect(StripPreviewScenario.leadingColumnCount(forWidth: 0.5) == 2)
    #expect(StripPreviewScenario.leadingColumnCount(forWidth: 0.25) == 4)
  }

  @Test func leadingColumnCountIsCapped() {
    #expect(
      StripPreviewScenario.leadingColumnCount(forWidth: 0.1)
        == StripPreviewScenario.maximumLeadingColumns)
    #expect(
      StripPreviewScenario.leadingColumnCount(forWidth: 0)
        == StripPreviewScenario.maximumLeadingColumns)
  }

  @Test func scrolledStripShowsColumnsLeftOfTheDisplay() throws {
    let config = LayoutConfig()
    let scenario = StripPreviewScenario(
      columnWidths: Array(repeating: half, count: 5), focusTrail: [1]
    ).withLeadingColumns(2, width: half)
    let geometry = StripPreviewGeometry(
      scenario: scenario, config: config, container: CGSize(width: 500, height: 150))
    let leftmost = try #require(geometry.windows.map(\.rect.minX).min())
    #expect(leftmost < geometry.displayRect.minX)
    let rightmost = try #require(geometry.windows.map(\.rect.maxX).max())
    #expect(rightmost > geometry.displayRect.maxX)
  }
}
