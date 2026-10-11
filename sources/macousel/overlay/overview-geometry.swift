import CoreGraphics
import StripCore

struct OverviewGeometry {
  struct Card: Identifiable {
    let content: OverviewSnapshot.Card
    let rect: CGRect
    let number: Int?
    let isSelected: Bool

    var id: WindowID { content.window }
  }

  let cards: [Card]
  let scale: Double

  init(snapshot: OverviewSnapshot, size: CGSize) {
    let columns = snapshot.columns
    let stripWidth = columns.reduce(0) { $0 + $1.width }
    guard stripWidth > 0, size.width > 0, size.height > 0 else {
      cards = []
      scale = 0
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
            number: row == 0 && ColumnCursor.places.contains(index + 1) ? index + 1 : nil,
            isSelected: card.window == snapshot.selection))
        y += rowHeights[row] + Metrics.Overview.stackGap
      }
      x += width + Metrics.Overview.columnGap
    }
    self.cards = cards
    self.scale = scale
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
