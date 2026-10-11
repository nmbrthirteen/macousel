import StripCore

extension StripPreviewScenario {
  static let maximumLeadingColumns = 4

  static func leadingColumnCount(forWidth fraction: Double) -> Int {
    guard fraction > 0 else { return maximumLeadingColumns }
    return min(max(Int((1 / fraction).rounded(.up)), 1), maximumLeadingColumns)
  }

  func withLeadingColumns(_ count: Int, width: ColumnWidth) -> StripPreviewScenario {
    guard count > 0 else { return self }
    return StripPreviewScenario(
      columnWidths: Array(repeating: width, count: count) + columnWidths,
      stackedColumn: stackedColumn.map { $0 + count },
      focusTrail: focusTrail.map { $0 + count },
      scrollOverride: scrollOverride)
  }
}
