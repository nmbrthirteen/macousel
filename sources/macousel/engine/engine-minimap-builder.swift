import CoreGraphics
import StripCore

struct EngineMinimapBuilder {
  static let cellWidth = 400.0

  let snapshot: EngineSnapshot
  let viewport: CGRect

  func build() -> MinimapSnapshot? {
    let columns = snapshot.tiledColumns.columns
    let visible = columns.indices.filter { columns[$0].isOnScreen(in: viewport) }
    guard columns.count > 1, let first = visible.first, let last = visible.last,
      visible.count < columns.count
    else { return nil }
    let focused = snapshot.focusedWindow?.windowId
    var built: [MinimapSnapshot.Column] = []
    var x = 0.0
    var edges: [(start: Double, end: Double)] = []
    for column in columns {
      let width = column.width ?? Self.cellWidth
      edges.append((x, x + width))
      built.append(minimapColumn(column, x: x, width: width, focused: focused))
      x += width
    }
    return MinimapSnapshot(
      columns: built, contentWidth: x, viewportOffset: edges[first].start,
      viewportWidth: edges[last].end - edges[first].start, animationResponse: nil)
  }

  private func minimapColumn(
    _ column: EngineColumns.Column, x: Double, width: Double, focused: Int32?
  ) -> MinimapSnapshot.Column {
    let rows = zip(column.windows, column.heightShares).compactMap { window, share in
      EngineWindowID.make(window.windowId).map { id in
        MinimapSnapshot.Row(window: id, bundleIdentifier: window.bundleId, height: share)
      }
    }
    let activeRow = column.windows.firstIndex { $0.windowId == focused }
    return MinimapSnapshot.Column(
      x: x, width: width, rows: rows, activeRow: activeRow ?? 0, isTabbed: false,
      isFocused: activeRow != nil)
  }
}
