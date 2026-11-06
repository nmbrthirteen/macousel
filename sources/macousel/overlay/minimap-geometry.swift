import CoreGraphics
import StripCore

struct MinimapGeometry {
  struct FocusRing: Equatable {
    let cell: WindowID
    let rect: CGRect
    let cornerRadius: Double
  }

  let containerWidth: Double
  let cells: [MinimapCell]
  let lens: CGRect
  let lensRadius: Double

  init(snapshot: MinimapSnapshot) {
    let padding = Metrics.Minimap.horizontalPadding
    containerWidth = Self.containerWidth(for: snapshot)
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
        of: column, index: index, start: start, scale: scale, containerSize: containerSize,
        isOnScreen: Self.isOnScreen(column, in: snapshot))
    }
    let outset = Metrics.Minimap.lensOutset
    let lensLeft = padding + (snapshot.viewportOffset - start) * scale - outset
    let lensRight = lensLeft + snapshot.viewportWidth * scale + 2 * outset
    lens = CGRect(
      x: lensLeft.rounded(), y: Metrics.Minimap.verticalPadding - outset,
      width: lensRight.rounded() - lensLeft.rounded(), height: Self.innerHeight + 2 * outset)
    lensRadius = MinimapConcentricRadius.radius(of: lens, in: containerSize)
  }

  static func containerWidth(for snapshot: MinimapSnapshot) -> Double {
    min(
      max(
        snapshot.contentWidth * Metrics.Minimap.stripScale
          + 2 * Metrics.Minimap.horizontalPadding,
        Metrics.Minimap.minimumWidth),
      Metrics.Minimap.maximumWidth)
  }

  var bounds: CGRect {
    CGRect(x: 0, y: 0, width: containerWidth, height: Metrics.Minimap.height)
  }

  var panelBounds: CGRect {
    CGRect(x: 0, y: 0, width: containerWidth, height: Metrics.Minimap.panelHeight)
  }

  var focusRing: FocusRing? {
    guard let cell = cells.first(where: \.isFocused) else { return nil }
    let outset = Metrics.Minimap.focusRingOutset
    return FocusRing(
      cell: cell.id, rect: cell.rect.insetBy(dx: -outset, dy: -outset),
      cornerRadius: cell.cornerRadius + outset)
  }

  func cell(at point: CGPoint) -> MinimapCell? {
    cells.first { $0.hitRect.contains(point) }
  }

  private static var innerHeight: Double {
    Metrics.Minimap.height - 2 * Metrics.Minimap.verticalPadding
  }

  // A column counts as on screen when at least half of it, or half of the viewport when
  // the column is wider than the screen, shows. Slivers peeking at the edges stay dimmed.
  private static func isOnScreen(_ column: MinimapSnapshot.Column, in snapshot: MinimapSnapshot)
    -> Bool
  {
    let viewportEnd = snapshot.viewportOffset + snapshot.viewportWidth
    let overlap =
      min(column.x + column.width, viewportEnd) - max(column.x, snapshot.viewportOffset)
    return overlap >= min(column.width, snapshot.viewportWidth) / 2
  }

  private static func cells(
    of column: MinimapSnapshot.Column, index: Int, start: Double, scale: Double,
    containerSize: CGSize, isOnScreen: Bool
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
        isFocused: column.isFocused && entry.window == active.window,
        isOnScreen: isOnScreen,
        isLeadRow: row == 0,
        dotCount: column.isTabbed ? min(column.rows.count, Metrics.Minimap.tabDotLimit) : 0,
        bundleIdentifier: entry.bundleIdentifier, containerSize: containerSize,
        isStacked: drawn.count > 1)
    }
  }
}
