import CoreGraphics
import StripCore

enum MinimapSampleSnapshot {
  static func make(config: LayoutConfig) -> MinimapSnapshot {
    let screen = PreviewMetrics.screenSize
    let scenario = StripPreviewScenario(
      columnWidths: Array(
        repeating: .fraction(PreviewMetrics.Sample.minimapColumnWidth),
        count: PreviewMetrics.Sample.minimapColumnCount),
      focusTrail: [PreviewMetrics.Sample.layoutRestingColumn])
    let strip = scenario.strip(viewportWidth: screen.width, config: config)
    let layout = strip.layout(in: CGRect(origin: .zero, size: screen), config: config)
    let origin = config.outerGap - strip.scrollOffset
    let columns = strip.columns.indices.compactMap { index -> MinimapSnapshot.Column? in
      let placements = layout.placements.filter { $0.column == index }
      guard let first = placements.first else { return nil }
      return MinimapSnapshot.Column(
        x: first.frame.minX - origin, width: first.frame.width,
        rows: placements.map {
          MinimapSnapshot.Row(window: $0.window, bundleIdentifier: nil, height: $0.frame.height)
        },
        activeRow: strip.columns[index].activeRow, isTabbed: false,
        isFocused: index == strip.focusedColumn)
    }
    return MinimapSnapshot(
      columns: columns, contentWidth: layout.contentWidth, viewportOffset: strip.scrollOffset,
      viewportWidth: screen.width - 2 * config.outerGap, animationResponse: nil)
  }
}
