import StripCore

extension OverviewSnapshot {
  func makeStrip() -> Strip {
    var strip = Strip()
    for column in columns {
      for card in column.cards { strip.append(card.window, width: .fixed(column.width)) }
    }
    for column in columns {
      guard let first = column.cards.first?.window else { continue }
      for (row, card) in column.cards.enumerated().dropFirst() {
        strip.stack(card.window, ontoColumnOf: first, atRow: row)
      }
      let weights = column.cards.map { $0.heightShare * Double(column.cards.count) }
      strip.setHeightWeights(weights, ofColumnContaining: first)
    }
    return strip
  }

  func rearranged(as strip: Strip) -> OverviewSnapshot {
    let cards = Dictionary(uniqueKeysWithValues: columns.flatMap(\.cards).map { ($0.window, $0) })
    let tabbed = Set(columns.filter(\.isTabbed).flatMap { $0.cards.map(\.window) })
    var result = self
    result.columns = strip.columns.map { column in
      var width = 0.0
      if case .fixed(let points) = column.width { width = points }
      let total = column.heightWeights.reduce(0, +)
      let members = zip(column.windows, column.heightWeights).compactMap { window, weight in
        cards[window].map { card -> Card in
          var moved = card
          moved.heightShare = total > 0 ? weight / total : 1
          return moved
        }
      }
      return Column(
        width: width, cards: members,
        isTabbed: members.count > 1 && tabbed.contains(members[0].window))
    }
    return result
  }
}
