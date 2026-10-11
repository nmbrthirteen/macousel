import SwiftUI

struct FlowLayout: Layout {
  let spacing: Double

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let rows = rows(for: proposal.width ?? .infinity, subviews: subviews)
    let height = rows.map(\.height).reduce(0, +) + spacing * Double(max(rows.count - 1, 0))
    return CGSize(width: rows.map(\.width).max() ?? 0, height: height)
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    var y = bounds.minY
    for row in rows(for: bounds.width, subviews: subviews) {
      var x = bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
      y += row.height + spacing
    }
  }

  private struct Row {
    var indices: [Int] = []
    var width = 0.0
    var height = 0.0
  }

  private func rows(for maxWidth: Double, subviews: Subviews) -> [Row] {
    var rows = [Row()]
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let gap = rows[rows.count - 1].indices.isEmpty ? 0 : spacing
      if rows[rows.count - 1].width + gap + size.width > maxWidth, !rows[rows.count - 1].indices.isEmpty {
        rows.append(Row())
      }
      let last = rows.count - 1
      rows[last].width += (rows[last].indices.isEmpty ? 0 : spacing) + size.width
      rows[last].height = max(rows[last].height, size.height)
      rows[last].indices.append(index)
    }
    return rows
  }
}
