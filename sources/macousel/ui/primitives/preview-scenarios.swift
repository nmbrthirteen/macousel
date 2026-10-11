import StripCore

enum PreviewScenarios {
  static func layout(
    config: LayoutConfig, focusTrail: [Int], hoveredPreset: Double?
  ) -> StripPreviewScenario {
    var widths = Array(
      repeating: ColumnWidth.fraction(config.defaultWidth),
      count: PreviewMetrics.Sample.layoutColumnCount)
    if let hoveredPreset, let focused = focusTrail.last, widths.indices.contains(focused) {
      widths[focused] = .fraction(hoveredPreset)
    }
    return StripPreviewScenario(columnWidths: widths, focusTrail: focusTrail)
  }

  static func motion(focusTrail: [Int]) -> StripPreviewScenario {
    StripPreviewScenario(
      columnWidths: Array(
        repeating: .fraction(PreviewMetrics.Sample.motionColumnWidth),
        count: PreviewMetrics.Sample.motionColumnCount),
      focusTrail: focusTrail)
  }

  static func rules() -> StripPreviewScenario {
    StripPreviewScenario(
      columnWidths: Array(
        repeating: .fraction(PreviewMetrics.Sample.rulesColumnWidth),
        count: PreviewMetrics.Sample.rulesColumnCount),
      focusTrail: [PreviewMetrics.Sample.rulesFocusedColumn])
  }

  static func swipe(scrollOffset: Double) -> StripPreviewScenario {
    StripPreviewScenario(
      columnWidths: Array(
        repeating: .fraction(PreviewMetrics.Swipe.columnWidth),
        count: PreviewMetrics.Swipe.columnCount),
      focusTrail: [PreviewMetrics.Swipe.focusedColumn], scrollOverride: scrollOffset)
  }

  static func tiledDisplay() -> StripPreviewScenario {
    StripPreviewScenario(
      columnWidths: PreviewMetrics.Sample.tiledColumnWidths.map { .fraction($0) },
      stackedColumn: PreviewMetrics.Sample.tiledStackedColumn,
      focusTrail: [PreviewMetrics.Sample.tiledFocusedColumn])
  }
}
