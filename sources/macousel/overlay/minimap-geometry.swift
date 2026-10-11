import CoreGraphics

struct MinimapGeometry {
  struct Cell: Identifiable {
    let id: Int
    let rect: CGRect
    let isFocused: Bool
  }

  struct Label: Identifiable {
    let number: Int
    let center: CGPoint

    var id: Int { number }
  }

  private static let columnGap = 1.5
  private static let highestNumberedColumn = 9
  private static let narrowestNumberedWidth = 14.0
  private static let rowsPerColumnLimit = 1000

  let cells: [Cell]
  let labels: [Label]
  let viewport: CGRect

  init(snapshot: MinimapSnapshot, size: CGSize) {
    let start = min(0, snapshot.viewportOffset)
    let end = max(snapshot.contentWidth, snapshot.viewportOffset + snapshot.viewportWidth)
    let span = end - start
    guard span > 0, size.width > 0, size.height > 0 else {
      cells = []
      labels = []
      viewport = .zero
      return
    }
    let scale = size.width / span
    var cells: [Cell] = []
    var labels: [Label] = []

    for (index, column) in snapshot.columns.enumerated() {
      let x = (column.x - start) * scale
      let width = max(column.width * scale - Self.columnGap, 1)
      let shares = column.rowShares.isEmpty ? [1] : column.rowShares
      let total = shares.reduce(0, +)
      guard total > 0 else { continue }
      let usableHeight = size.height - Self.columnGap * Double(shares.count - 1)

      var y = 0.0
      for (row, share) in shares.enumerated() {
        let height = max(usableHeight * share / total, 1)
        cells.append(
          Cell(
            id: index * Self.rowsPerColumnLimit + row,
            rect: CGRect(x: x, y: y, width: width, height: height),
            isFocused: column.isFocused))
        y += height + Self.columnGap
      }
      if index < Self.highestNumberedColumn, width >= Self.narrowestNumberedWidth {
        labels.append(
          Label(number: index + 1, center: CGPoint(x: x + width / 2, y: size.height / 2)))
      }
    }

    self.cells = cells
    self.labels = labels
    viewport = CGRect(
      x: (snapshot.viewportOffset - start) * scale, y: 0,
      width: snapshot.viewportWidth * scale, height: size.height)
  }
}
