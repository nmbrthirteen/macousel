import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct SettingsPreviewGeometryTests {
  private static let container = CGSize(width: 500, height: 150)
  private static let screen = PreviewMetrics.screenSize

  private func geometry(
    _ scenario: StripPreviewScenario, config: LayoutConfig = LayoutConfig(),
    container: CGSize = SettingsPreviewGeometryTests.container,
    showsOverflow: Bool = true
  ) -> StripPreviewGeometry {
    StripPreviewGeometry(
      scenario: scenario, config: config, container: container, showsOverflow: showsOverflow)
  }

  private func halves(count: Int = 4, focus: Int = 1) -> StripPreviewScenario {
    StripPreviewScenario(
      columnWidths: Array(repeating: .fraction(0.5), count: count), focusTrail: [focus])
  }

  @Test func displayKeepsTheScreenAspectInsideTheContainer() {
    let result = geometry(halves())
    #expect(abs(result.displayRect.height - 130) < 0.001)
    #expect(abs(result.displayRect.width / result.displayRect.height - 1.6) < 0.001)
    #expect(abs(result.displayRect.midX - 250) < 0.001)
    #expect(abs(result.displayRect.midY - 75) < 0.001)
  }

  @Test func narrowContainerShrinksTheDisplayToFitItsWidth() {
    let result = geometry(halves(), container: CGSize(width: 200, height: 150))
    #expect(abs(result.displayRect.width - 176) < 0.001)
    #expect(abs(result.displayRect.height - 110) < 0.001)
  }

  @Test func windowFramesAreTheEngineFramesScaledIntoTheDisplay() throws {
    let config = LayoutConfig()
    let scenario = halves()
    let result = geometry(scenario, config: config)
    let strip = scenario.strip(viewportWidth: Self.screen.width, config: config)
    let layout = strip.layout(in: CGRect(origin: .zero, size: Self.screen), config: config)
    for window in result.windows {
      let frame = try #require(layout[window.id]?.frame)
      let expectedX = result.displayRect.minX + frame.minX * result.scale
      let expectedWidth = frame.width * result.scale
      #expect(abs(window.rect.minX - expectedX) < 0.001)
      #expect(abs(window.rect.width - expectedWidth) < 0.001)
    }
  }

  @Test func neverModeLeavesTheSecondColumnOneColumnPitchFromTheEdge() throws {
    let result = geometry(halves())
    let focused = try #require(result.windows.first { $0.isFocused })
    let expected = result.displayRect.minX + (8 + 628 + 8) * result.scale
    #expect(abs(focused.rect.minX - expected) < 0.001)
  }

  @Test func alwaysModeCentresTheFocusedWindow() throws {
    var config = LayoutConfig()
    config.centerMode = .always
    let result = geometry(halves(), config: config)
    let focused = try #require(result.windows.first { $0.isFocused })
    #expect(abs(focused.rect.midX - result.displayRect.midX) < 0.5 * result.scale + 0.001)
  }

  @Test func onOverflowModeCentresTheFocusedWindowWhenTheStripIsWider() throws {
    var config = LayoutConfig()
    config.centerMode = .onOverflow
    let result = geometry(halves(), config: config)
    let focused = try #require(result.windows.first { $0.isFocused })
    #expect(abs(focused.rect.midX - result.displayRect.midX) < 0.5 * result.scale + 0.001)
  }

  @Test func onOverflowModeCentresAStripThatFits() throws {
    var config = LayoutConfig()
    config.centerMode = .onOverflow
    let scenario = StripPreviewScenario(
      columnWidths: [.fraction(0.3), .fraction(0.3)], focusTrail: [0])
    let result = geometry(scenario, config: config)
    let left = try #require(result.windows.map { $0.rect.minX }.min())
    let right = try #require(result.windows.map { $0.rect.maxX }.max())
    #expect(abs((left - result.displayRect.minX) - (result.displayRect.maxX - right)) < 0.5)
  }

  @Test func neverModeKeepsAScrolledStripWhenFocusReturnsInsideTheViewport() throws {
    let scenario = StripPreviewScenario(
      columnWidths: Array(repeating: .fraction(0.5), count: 4), focusTrail: [1, 3, 1])
    let result = geometry(scenario)
    let focused = try #require(result.windows.first { $0.isFocused })
    #expect(abs(focused.rect.minX - result.displayRect.minX - 8 * result.scale) < 0.5)
  }

  @Test(arguments: [(8.0, 8.0), (24.0, 8.0), (40.0, 0.0)])
  func gapsScaleWithTheDisplay(inner: Double, outer: Double) throws {
    let config = LayoutConfig(innerGap: inner, outerGap: outer)
    let result = geometry(halves(), config: config)
    let first = try #require(result.windows.first { $0.column == 0 })
    let second = try #require(result.windows.first { $0.column == 1 })
    #expect(abs((second.rect.minX - first.rect.maxX) - inner * result.scale) < 0.2)
    #expect(abs(first.rect.minY - result.displayRect.minY - outer * result.scale) < 0.2)
  }

  @Test func windowsOutsideTheContainerAreDropped() {
    let result = geometry(halves(count: 12, focus: 0))
    #expect(result.windows.count < 12)
    #expect(result.windows.allSatisfy { $0.rect.intersects(CGRect(origin: .zero, size: Self.container)) })
  }

  @Test func windowsPastTheScreenEdgeStayForTheFadedOverflow() {
    let result = geometry(halves(count: 6, focus: 0))
    #expect(result.windows.contains { $0.rect.maxX > result.displayRect.maxX })
  }

  @Test func fadeRegionsRunFromTheDisplayEdgesToTheContainerEdges() {
    let result = geometry(halves())
    #expect(result.leadingFade.minX == 0)
    #expect(abs(result.leadingFade.maxX - result.displayRect.minX) < 0.001)
    #expect(abs(result.trailingFade.minX - result.displayRect.maxX) < 0.001)
    #expect(abs(result.trailingFade.maxX - Self.container.width) < 0.001)
  }

  @Test func embeddedPreviewFillsTheContainerWithoutFades() {
    let result = geometry(halves(), showsOverflow: false)
    #expect(result.displayRect == CGRect(origin: .zero, size: Self.container))
    #expect(result.leadingFade.width == 0)
    #expect(result.trailingFade.width == 0)
  }

  @Test func stackedColumnHoldsTwoRowsAtTheSameX() throws {
    let scenario = StripPreviewScenario(
      columnWidths: [.fraction(0.5), .fraction(0.5)], stackedColumn: 1, focusTrail: [0])
    let result = geometry(scenario)
    let rows = result.windows.filter { $0.column == 1 }.sorted { $0.row < $1.row }
    #expect(rows.count == 2)
    #expect(rows[0].rect.minX == rows[1].rect.minX)
    #expect(rows[1].rect.minY > rows[0].rect.maxY)
  }

  @Test func windowIdentitiesStayStableAcrossFocusChanges() {
    let before = geometry(halves(focus: 1)).windows.map(\.id)
    let after = geometry(halves(focus: 2)).windows.filter { before.contains($0.id) }.map(\.id)
    #expect(!after.isEmpty)
    #expect(Set(after).isSubset(of: Set(before)))
  }

  @Test func borderWidthIsScaledDownByTheBorderFactor() {
    #expect(geometry(halves()).borderLineWidth(for: 3) == 1.5)
    #expect(geometry(halves()).borderLineWidth(for: 8) == 4)
  }

  @Test func floatingCardRectFollowsTheDisplay() {
    let result = geometry(halves())
    let card = FloatingPreviewCard(unitFrame: CGRect(x: 0.5, y: 0.5, width: 0.25, height: 0.25), isAboveTiled: true)
    let rect = result.cardRect(card)
    #expect(abs(rect.minX - (result.displayRect.minX + result.displayRect.width / 2)) < 0.001)
    #expect(abs(rect.width - result.displayRect.width / 4) < 0.001)
  }
}
