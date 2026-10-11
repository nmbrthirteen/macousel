import CoreGraphics

struct MinimapGeometry {
  let capsuleWidth: Double
  let cells: [MinimapCell]
  let lens: CGRect

  init(snapshot: MinimapSnapshot) {
    let padding = Metrics.Minimap.horizontalPadding
    capsuleWidth = min(
      max(
        snapshot.contentWidth * Metrics.Minimap.stripScale + 2 * padding,
        Metrics.Minimap.minimumWidth),
      Metrics.Minimap.maximumWidth)
    let start = min(0, snapshot.viewportOffset)
    let end = max(snapshot.contentWidth, snapshot.viewportOffset + snapshot.viewportWidth)
    guard end > start else {
      cells = []
      lens = .zero
      return
    }
    let scale = (capsuleWidth - 2 * padding) / (end - start)
    cells = snapshot.columns.enumerated().flatMap { index, column in
      Self.cells(of: column, number: index + 1, start: start, scale: scale)
    }
    let outset = Metrics.Minimap.lensOutset
    lens = CGRect(
      x: padding + (snapshot.viewportOffset - start) * scale - outset,
      y: Metrics.Minimap.verticalPadding - outset,
      width: snapshot.viewportWidth * scale + 2 * outset,
      height: Self.innerHeight + 2 * outset)
  }

  private static var innerHeight: Double {
    Metrics.Minimap.height - 2 * Metrics.Minimap.verticalPadding
  }

  private static func cells(
    of column: MinimapSnapshot.Column, number: Int, start: Double, scale: Double
  ) -> [MinimapCell] {
    let gap = Metrics.Minimap.columnGap
    let x = Metrics.Minimap.horizontalPadding + (column.x - start) * scale + gap / 2
    let width = max(column.width * scale - gap, 1)
    guard let first = column.rows.first else { return [] }
    let active = column.rows.indices.contains(column.activeRow) ? column.rows[column.activeRow] : first
    let drawn = column.isTabbed ? [active] : column.rows
    let identities = column.isTabbed ? [first.window] : drawn.map(\.window)
    let total = drawn.reduce(0) { $0 + $1.height }
    guard total > 0 else { return [] }
    let rowGap = Metrics.Minimap.rowGap
    let available = innerHeight - rowGap * Double(drawn.count - 1)

    var y = Metrics.Minimap.verticalPadding
    return drawn.enumerated().map { row, entry in
      let height = max(available * entry.height / total, 1)
      defer { y += height + rowGap }
      return MinimapCell(
        id: identities[row],
        rect: CGRect(x: x, y: y, width: width, height: height),
        isFocused: column.isFocused,
        columnNumber: number,
        isLeadRow: row == 0,
        dotCount: column.isTabbed ? min(column.rows.count, Metrics.Minimap.tabDotLimit) : 0,
        bundleIdentifier: entry.bundleIdentifier)
    }
  }
}
