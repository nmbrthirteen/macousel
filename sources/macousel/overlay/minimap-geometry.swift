import CoreGraphics

struct MinimapGeometry {
  let containerWidth: Double
  let cells: [MinimapCell]
  let lens: CGRect
  let lensRadius: Double

  init(snapshot: MinimapSnapshot) {
    let padding = Metrics.Minimap.horizontalPadding
    containerWidth = min(
      max(
        snapshot.contentWidth * Metrics.Minimap.stripScale + 2 * padding,
        Metrics.Minimap.minimumWidth),
      Metrics.Minimap.maximumWidth)
    let start = min(0, snapshot.viewportOffset)
    let end = max(snapshot.contentWidth, snapshot.viewportOffset + snapshot.viewportWidth)
    guard end > start else {
      cells = []
      lens = .zero
      lensRadius = 0
      return
    }
    let containerSize = CGSize(width: containerWidth, height: Metrics.Minimap.height)
    let scale = (containerWidth - 2 * padding) / (end - start)
    cells = snapshot.columns.enumerated().flatMap { index, column in
      Self.cells(
        of: column, index: index, start: start, scale: scale, containerSize: containerSize)
    }
    let outset = Metrics.Minimap.lensOutset
    let lensLeft = padding + (snapshot.viewportOffset - start) * scale - outset
    let lensRight = lensLeft + snapshot.viewportWidth * scale + 2 * outset
    lens = CGRect(
      x: lensLeft.rounded(), y: Metrics.Minimap.verticalPadding - outset,
      width: lensRight.rounded() - lensLeft.rounded(), height: Self.innerHeight + 2 * outset)
    lensRadius = MinimapConcentricRadius.radius(of: lens, in: containerSize)
  }

  var bounds: CGRect {
    CGRect(x: 0, y: 0, width: containerWidth, height: Metrics.Minimap.height)
  }

  func cell(at point: CGPoint) -> MinimapCell? {
    cells.first { $0.hitRect.contains(point) }
  }

  private static var innerHeight: Double {
    Metrics.Minimap.height - 2 * Metrics.Minimap.verticalPadding
  }

  private static func cells(
    of column: MinimapSnapshot.Column, index: Int, start: Double, scale: Double,
    containerSize: CGSize
  ) -> [MinimapCell] {
    let gap = Metrics.Minimap.columnGap
    let rawLeft = Metrics.Minimap.horizontalPadding + (column.x - start) * scale + gap / 2
    let left = rawLeft.rounded()
    let width = max((rawLeft + column.width * scale - gap).rounded() - left, 1)
    guard let first = column.rows.first else { return [] }
    let active = column.rows.indices.contains(column.activeRow) ? column.rows[column.activeRow] : first
    let drawn = column.isTabbed ? [active] : column.rows
    let identities = column.isTabbed ? [first.window] : drawn.map(\.window)
    let firstRow = column.isTabbed ? column.rows.firstIndex(of: active) ?? 0 : 0
    let total = drawn.reduce(0) { $0 + $1.height }
    guard total > 0 else { return [] }
    let rowGap = Metrics.Minimap.rowGap
    let available = innerHeight - rowGap * Double(drawn.count - 1)

    var y = Metrics.Minimap.verticalPadding
    return drawn.enumerated().map { row, entry in
      let rawHeight = available * entry.height / total
      let top = y.rounded()
      let height = max((y + rawHeight).rounded() - top, 1)
      defer { y += rawHeight + rowGap }
      return MinimapCell(
        id: identities[row], window: entry.window, column: index, row: firstRow + row,
        rect: CGRect(x: left, y: top, width: width, height: height),
        isFocused: column.isFocused,
        isLeadRow: row == 0,
        dotCount: column.isTabbed ? min(column.rows.count, Metrics.Minimap.tabDotLimit) : 0,
        bundleIdentifier: entry.bundleIdentifier, containerSize: containerSize,
        isStacked: drawn.count > 1)
    }
  }
}
