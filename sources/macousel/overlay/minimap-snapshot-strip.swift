import StripCore

extension MinimapSnapshot {
  func makeStrip() -> Strip {
    var strip = Strip()
    for column in columns {
      for row in column.rows { strip.append(row.window, width: .fixed(column.width)) }
    }
    for column in columns {
      guard let first = column.rows.first?.window else { continue }
      for (index, row) in column.rows.enumerated().dropFirst() {
        strip.stack(row.window, ontoColumnOf: first, atRow: index)
      }
      let total = column.rows.reduce(0) { $0 + $1.height }
      let weights = column.rows.map { total > 0 ? $0.height / total * Double(column.rows.count) : 1 }
      strip.setHeightWeights(weights, ofColumnContaining: first)
    }
    return strip
  }

  func rearranged(as strip: Strip) -> MinimapSnapshot {
    let rows = Dictionary(uniqueKeysWithValues: columns.flatMap(\.rows).map { ($0.window, $0) })
    let tabbed = Set(columns.filter(\.isTabbed).flatMap { $0.rows.map(\.window) })
    let active = Set(columns.compactMap(\.activeWindow))
    var x = 0.0
    var result = self
    result.columns = strip.columns.map { column in
      let weightSum = column.heightWeights.reduce(0, +)
      let members = zip(column.windows, column.heightWeights).compactMap { window, weight in
        rows[window].map { row -> Row in
          var moved = row
          moved.height = weightSum > 0 ? weight / weightSum : 1
          return moved
        }
      }
      var width = 0.0
      if case .fixed(let points) = column.width { width = points }
      defer { x += width + innerGap }
      return Column(
        x: x, width: width, rows: members,
        activeRow: members.firstIndex { active.contains($0.window) } ?? 0,
        isTabbed: members.count > 1 && members.first.map { tabbed.contains($0.window) } == true,
        isFocused: members.contains { $0.window == focusedWindow })
    }
    return result
  }
}
