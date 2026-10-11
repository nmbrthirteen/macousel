import CoreGraphics
import Testing

@testable import StripCore

struct DropGrid {
  static let columnWidth = 100.0
  static let columnGap = 10.0
  static let height = 400.0

  let strip: Strip
  let layout: StripLayout
  let viewport: CGRect

  init(_ columns: [[UInt32]]) {
    var strip = Strip()
    var placements: [Placement] = []
    for window in columns.flatMap({ $0 }) { strip.append(id(window), width: .fraction(0.25)) }
    for windows in columns {
      for (row, window) in windows.enumerated().dropFirst() {
        strip.stack(id(window), ontoColumnOf: id(windows[0]), atRow: row)
      }
    }
    for (index, windows) in columns.enumerated() {
      let rowHeight = (Self.height - Self.columnGap * Double(windows.count - 1)) / Double(windows.count)
      for (row, window) in windows.enumerated() {
        let frame = CGRect(
          x: Double(index) * (Self.columnWidth + Self.columnGap),
          y: Double(row) * (rowHeight + Self.columnGap), width: Self.columnWidth,
          height: rowHeight)
        placements.append(
          Placement(
            window: id(window), frame: frame, visibility: .full, column: index, row: row))
      }
    }
    self.strip = strip
    layout = StripLayout(placements: placements, contentWidth: 0)
    viewport = CGRect(
      x: 0, y: 0, width: Double(columns.count) * (Self.columnWidth + Self.columnGap),
      height: Self.height)
  }

  func rule(dragging window: UInt32) -> DropRule {
    DropRule(strip: strip, layout: layout, viewport: viewport, dragging: id(window))
  }

  func target(dragging window: UInt32, at x: Double, _ y: Double) -> DropTarget {
    rule(dragging: window).target(at: CGPoint(x: x, y: y))
  }

  func columns(afterDropping window: UInt32, at x: Double, _ y: Double) -> [[UInt32]] {
    let rule = rule(dragging: window)
    let result = rule.applying(rule.target(at: CGPoint(x: x, y: y)))
    return result.columns.map { $0.windows.map(\.rawValue) }
  }
}
