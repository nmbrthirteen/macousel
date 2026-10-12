import CoreGraphics
import StripCore

struct EngineDropTargeting {
  let columns: EngineColumns
  let viewport: CGRect

  func target(dragging window: WindowID, at point: CGPoint) -> DropTarget {
    DropRule(strip: strip, layout: layout, viewport: viewport, dragging: window).target(at: point)
  }

  private var strip: Strip {
    var result = Strip()
    for column in columns.columns {
      let members = column.windowIDs
      guard let first = members.first else { continue }
      result.append(first, width: .fixed(column.width ?? 0))
      for (row, member) in members.enumerated().dropFirst() {
        result.stack(member, ontoColumnOf: first, atRow: row)
      }
    }
    return result
  }

  private var layout: StripLayout {
    let placements = columns.windowIDs.enumerated().flatMap { column, members in
      members.enumerated().compactMap { row, member in
        placement(of: member, column: column, row: row)
      }
    }
    return StripLayout(placements: placements, contentWidth: viewport.width)
  }

  private func placement(of window: WindowID, column: Int, row: Int) -> Placement? {
    columns.frame(of: window).map {
      Placement(window: window, frame: $0, visibility: .full, column: column, row: row)
    }
  }
}
