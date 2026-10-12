import CoreGraphics
import StripCore

struct OverviewGeometry {
  struct Card: Identifiable {
    let content: OverviewSnapshot.Card
    let rect: CGRect
    let number: Int?
    let isSelected: Bool
    let column: Int
    let row: Int

    var id: WindowID { content.window }
  }

  let cards: [Card]
  let scale: Double
  let stripBounds: CGRect
  let hitAreas: OverviewHitAreas

  var dropLayout: StripLayout {
    StripLayout(
      placements: cards.map {
        Placement(
          window: $0.id, frame: $0.rect, visibility: .full, column: $0.column, row: $0.row)
      }, contentWidth: stripBounds.width)
  }

  init(snapshot: OverviewSnapshot, size: CGSize) {
    let columns = snapshot.columns
    let stripWidth = columns.reduce(0) { $0 + $1.width }
    guard stripWidth > 0, size.width > 0, size.height > 0 else {
      cards = []
      scale = 0
      stripBounds = .zero
      hitAreas = OverviewHitAreas(cards: [])
      return
    }
    let gaps = Metrics.Overview.columnGap * Double(columns.count - 1)
    let available = max(size.width - 2 * Metrics.Overview.edgeMargin - gaps, 0)
    let scale = min(Metrics.Overview.maximumScale, available / stripWidth)
    let height = snapshot.stripHeight * scale
    let top = (size.height - height) / 2
    var x = (size.width - stripWidth * scale - gaps) / 2
    var cards: [Card] = []

    for (index, column) in columns.enumerated() {
      let width = column.width * scale
      let rowHeights = Self.rowHeights(of: column, totalHeight: height)
      var y = top
      for (row, card) in column.cards.enumerated() {
        cards.append(
          Card(
            content: card,
            rect: CGRect(x: x, y: y, width: width, height: rowHeights[row]),
            number: row == 0 ? Self.number(ofColumn: index, among: columns.count) : nil,
            isSelected: card.window == snapshot.selection, column: index, row: row))
        y += rowHeights[row] + Metrics.Overview.stackGap
      }
      x += width + Metrics.Overview.columnGap
    }
    self.cards = cards
    self.scale = scale
    stripBounds = CGRect(x: 0, y: top, width: size.width, height: height)
    hitAreas =
      snapshot.allowsResize
      ? OverviewHitAreas(
        cards: cards, tabbedColumns: Set(columns.indices.filter { columns[$0].isTabbed }))
      : OverviewHitAreas(cards: [])
  }

  private static func number(ofColumn index: Int, among count: Int) -> Int? {
    if index == count - 1 { return min(count, Metrics.Overview.lastPlace) }
    return index + 1 < Metrics.Overview.lastPlace ? index + 1 : nil
  }

  private static func rowHeights(of column: OverviewSnapshot.Column, totalHeight: Double)
    -> [Double]
  {
    let usable = max(totalHeight - Metrics.Overview.stackGap * Double(column.cards.count - 1), 0)
    let totalShare = column.cards.reduce(0) { $0 + $1.heightShare }
    guard totalShare > 0 else {
      return column.cards.map { _ in usable / Double(column.cards.count) }
    }
    return column.cards.map { usable * $0.heightShare / totalShare }
  }
}
