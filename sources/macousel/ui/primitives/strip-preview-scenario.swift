import StripCore

struct StripPreviewScenario: Equatable {
  static let stackedWindow = WindowID(100)

  var columnWidths: [ColumnWidth]
  var stackedColumn: Int?
  var focusTrail: [Int]
  var scrollOverride: Double?

  init(
    columnWidths: [ColumnWidth], stackedColumn: Int? = nil, focusTrail: [Int],
    scrollOverride: Double? = nil
  ) {
    self.columnWidths = columnWidths
    self.stackedColumn = stackedColumn
    self.focusTrail = focusTrail
    self.scrollOverride = scrollOverride
  }

  var focusedColumn: Int { focusTrail.last ?? 0 }

  func strip(viewportWidth: Double, config: LayoutConfig) -> Strip {
    var strip = Strip()
    for (index, width) in columnWidths.enumerated() {
      strip.append(WindowID(UInt32(index + 1)), width: width)
    }
    if let stacked = stackedColumn, columnWidths.indices.contains(stacked) {
      strip.append(Self.stackedWindow, width: .fraction(1))
      strip.stack(Self.stackedWindow, ontoColumnOf: WindowID(UInt32(stacked + 1)), atRow: 1)
    }
    guard !strip.columns.isEmpty else { return strip }
    if let scrollOverride {
      strip.focusColumn(clamped(focusedColumn, in: strip))
      strip.scrollOffset = scrollOverride
      return strip
    }
    for index in focusTrail {
      strip.focusColumn(clamped(index, in: strip))
      strip.scrollToFocus(viewportWidth: viewportWidth, config: config)
    }
    return strip
  }

  private func clamped(_ index: Int, in strip: Strip) -> Int {
    min(max(index, 0), strip.columns.count - 1)
  }
}
