import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct SettingsPreviewScenarioTests {
  private func widths(of scenario: StripPreviewScenario, config: LayoutConfig = LayoutConfig())
    -> [Double]
  {
    let geometry = StripPreviewGeometry(
      scenario: scenario, config: config, container: CGSize(width: 2000, height: 600),
      showsOverflow: false)
    return geometry.windows.sorted { $0.column < $1.column }.map { $0.rect.width }
  }

  @Test func layoutSampleHasFourColumnsAtTheDefaultWidth() {
    var config = LayoutConfig()
    config.defaultWidth = 0.25
    let scenario = PreviewScenarios.layout(config: config, focusTrail: [1], hoveredPreset: nil)
    let expected: [ColumnWidth] = [.fraction(0.25), .fraction(0.25), .fraction(0.25), .fraction(0.25)]
    #expect(scenario.columnWidths == expected)
    #expect(scenario.focusedColumn == 1)
  }

  @Test func defaultWidthChangesTheSampleWindowWidths() {
    var narrow = LayoutConfig()
    narrow.defaultWidth = 0.25
    var wide = LayoutConfig()
    wide.defaultWidth = 0.5
    let narrowWidths = widths(
      of: PreviewScenarios.layout(config: narrow, focusTrail: [1], hoveredPreset: nil),
      config: narrow)
    let wideWidths = widths(
      of: PreviewScenarios.layout(config: wide, focusTrail: [1], hoveredPreset: nil), config: wide)
    #expect(narrowWidths.allSatisfy { $0 < (wideWidths.first ?? 0) })
    #expect(abs((wideWidths.first ?? 0) / (narrowWidths.first ?? 1) - 2) < 0.1)
  }

  @Test func hoveredPresetResizesOnlyTheFocusedColumn() {
    let config = LayoutConfig()
    let scenario = PreviewScenarios.layout(config: config, focusTrail: [1], hoveredPreset: 0.75)
    #expect(scenario.columnWidths[1] == .fraction(0.75))
    #expect(scenario.columnWidths[0] == .fraction(0.5))
    #expect(scenario.columnWidths[2] == .fraction(0.5))
    let sample = widths(of: scenario, config: config)
    #expect(sample[1] > sample[0])
  }

  @Test func leavingThePresetRestoresTheDefaultWidth() {
    let config = LayoutConfig()
    let hovered = PreviewScenarios.layout(config: config, focusTrail: [1], hoveredPreset: 0.25)
    let restored = PreviewScenarios.layout(config: config, focusTrail: [1], hoveredPreset: nil)
    #expect(hovered != restored)
    let expected: [ColumnWidth] = [.fraction(0.5), .fraction(0.5), .fraction(0.5), .fraction(0.5)]
    #expect(restored.columnWidths == expected)
  }

  @Test func motionSampleScrollsWhenFocusMovesRight() throws {
    let config = LayoutConfig()
    let resting = StripPreviewGeometry(
      scenario: PreviewScenarios.motion(focusTrail: [1]), config: config,
      container: CGSize(width: 500, height: 150))
    let moved = StripPreviewGeometry(
      scenario: PreviewScenarios.motion(focusTrail: [1, 2]), config: config,
      container: CGSize(width: 500, height: 150))
    let before = try #require(resting.windows.first { $0.column == 0 })
    let after = try #require(moved.windows.first { $0.column == 0 })
    #expect(after.rect.minX < before.rect.minX)
  }

  @Test func rulesSampleFocusesTheSecondColumn() {
    #expect(PreviewScenarios.rules().focusedColumn == 1)
  }

  @Test func tiledDisplaySampleStacksOneColumn() {
    let scenario = PreviewScenarios.tiledDisplay()
    let strip = scenario.strip(viewportWidth: 1280, config: LayoutConfig())
    #expect(strip.columns.map { $0.windows.count } == [1, 2, 1])
  }

  @Test func swipeSampleUsesTheGivenScrollOffset() {
    let scenario = PreviewScenarios.swipe(scrollOffset: 500)
    let strip = scenario.strip(viewportWidth: 1280, config: LayoutConfig())
    #expect(strip.scrollOffset == 500)
  }

  @Test func minimapSampleCoversTheViewportInsideTheContent() {
    let snapshot = MinimapSampleSnapshot.make(config: LayoutConfig())
    #expect(snapshot.columns.count == 5)
    #expect(snapshot.contentWidth > snapshot.viewportWidth)
    #expect(snapshot.columns.filter(\.isFocused).count == 1)
  }

  @Test func descriptionsStateTheCurrentSettings() {
    var config = LayoutConfig()
    config.innerGap = 12
    #expect(PreviewDescription.layout(config).contains("12 points between windows"))
    #expect(PreviewDescription.layout(config).contains("half the screen wide"))
    config.defaultWidth = 0.25
    #expect(PreviewDescription.layout(config).contains("25% of the screen wide"))
    #expect(PreviewDescription.floating(keepsOnTop: false).contains("behind"))
  }
}
