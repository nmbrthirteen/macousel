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
  let floatingCards: [Card]
  let floatingTitleOrigin: CGPoint?
  let scale: Double
  let stripBounds: CGRect
  let hitAreas: OverviewHitAreas

  var everyCard: [Card] { cards + floatingCards }

  var cornerRadius: Double { OverlayRadius.overviewCard(scale: scale) }

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
      floatingCards = []
      floatingTitleOrigin = nil
      scale = 0
      stripBounds = .zero
      hitAreas = OverviewHitAreas(cards: [])
      return
    }
    let gaps = Metrics.Overview.columnGap * Double(columns.count - 1)
    let available = max(size.width - 2 * Metrics.Overview.edgeMargin - gaps, 0)
    let band = snapshot.floating.isEmpty ? 0 : Self.floatingBand
    let availableHeight = max(size.height - 2 * Metrics.Overview.verticalMargin - band, 0)
    let tallest =
      snapshot.stripHeight > 0 ? availableHeight / snapshot.stripHeight : Double.infinity
    let scale = min(Metrics.Overview.maximumScale, available / stripWidth, tallest)
    let height = snapshot.stripHeight * scale
    let top = band + (size.height - band - height) / 2
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
    let floating = Self.floatingRow(
      snapshot.floating, scale: scale, width: size.width, top: top - band,
      selection: snapshot.selection)
    floatingCards = floating
    floatingTitleOrigin = floating.first.map { CGPoint(x: $0.rect.minX, y: top - band) }
    self.scale = scale
    stripBounds = CGRect(x: 0, y: top, width: size.width, height: height)
    hitAreas =
      snapshot.allowsResize
      ? OverviewHitAreas(
        cards: cards, tabbedColumns: Set(columns.indices.filter { columns[$0].isTabbed }))
      : OverviewHitAreas(cards: [])
  }

  private static var floatingBand: Double {
    Metrics.Overview.floatingTitleHeight + Metrics.Overview.floatingRowHeight
      + Metrics.Overview.floatingRowGap
  }

  // Cards keep the strip's scale so a floating window reads at its size against the columns,
  // then shrink to fit the row's height and the overview's width.
  private static func floatingRow(
    _ floating: [OverviewSnapshot.Card], scale: Double, width: Double, top: Double,
    selection: WindowID?
  ) -> [Card] {
    let rowHeight = Metrics.Overview.floatingRowHeight
    let sizes = floating.map { card -> CGSize in
      guard let frame = card.frame, frame.width > 0, frame.height > 0 else {
        return CGSize(width: rowHeight * Metrics.Overview.floatingAspectRatio, height: rowHeight)
      }
      let fit = min(scale, rowHeight / frame.height)
      return CGSize(width: frame.width * fit, height: frame.height * fit)
    }
    let gaps = Metrics.Overview.columnGap * Double(max(floating.count - 1, 0))
    let natural = sizes.reduce(0) { $0 + $1.width }
    let available = max(width - 2 * Metrics.Overview.edgeMargin - gaps, 0)
    let shrink = natural > available && natural > 0 ? available / natural : 1
    var x = (width - natural * shrink - gaps) / 2
    let y = top + Metrics.Overview.floatingTitleHeight
    return zip(floating, sizes).enumerated().map { index, pair in
      let (card, size) = pair
      let rect = CGRect(x: x, y: y, width: size.width * shrink, height: size.height * shrink)
      x += rect.width + Metrics.Overview.columnGap
      return Card(
        content: card, rect: rect, number: nil, isSelected: card.window == selection,
        column: index, row: 0)
    }
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
