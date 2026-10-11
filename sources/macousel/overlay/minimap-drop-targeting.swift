import CoreGraphics
import StripCore

struct MinimapDropTargeting {
  let snapshot: MinimapSnapshot
  let geometry: MinimapGeometry

  func target(dragging window: WindowID, at point: CGPoint) -> DropTarget {
    guard geometry.bounds.contains(point) else { return .nowhere }
    return DropRule(
      strip: snapshot.makeStrip(), layout: layout, viewport: geometry.bounds, dragging: window
    ).target(at: point)
  }

  private var layout: StripLayout {
    StripLayout(
      placements: snapshot.columns.indices.flatMap { placements(ofColumn: $0) },
      contentWidth: geometry.containerWidth)
  }

  private func placements(ofColumn index: Int) -> [Placement] {
    let column = snapshot.columns[index]
    let cells = geometry.cells.filter { $0.column == index }
    guard let lead = cells.first else { return [] }
    return column.rows.enumerated().map { row, entry in
      Placement(
        window: entry.window, frame: (cells.first { $0.row == row } ?? lead).hitRect,
        visibility: .full, column: index, row: row,
        isBehindTab: column.isTabbed && row != column.activeRow)
    }
  }
}
