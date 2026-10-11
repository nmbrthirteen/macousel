import CoreGraphics
import StripCore

struct OverviewHitAreas {
  struct Edge: Equatable {
    let column: Int
    let window: WindowID
    let rect: CGRect
  }

  struct Divider: Equatable {
    let column: Int
    let upper: WindowID
    let lower: WindowID
    let rect: CGRect
  }

  let edges: [Edge]
  let dividers: [Divider]

  init(cards: [OverviewGeometry.Card], tabbedColumns: Set<Int> = []) {
    let columns = Dictionary(grouping: cards, by: \.column)
    edges = columns.keys.sorted().compactMap { index in
      let members = columns[index] ?? []
      guard let first = members.first, let last = members.last else { return nil }
      let rect = CGRect(
        x: first.rect.maxX - Metrics.Overview.edgeHitWidth, y: first.rect.minY,
        width: Metrics.Overview.edgeHitWidth + Metrics.Overview.columnGap / 2,
        height: last.rect.maxY - first.rect.minY)
      return Edge(column: index, window: first.id, rect: rect)
    }
    dividers = columns.keys.sorted().filter { !tabbedColumns.contains($0) }.flatMap { index in
      let members = columns[index] ?? []
      return zip(members, members.dropFirst()).map { upper, lower in
        let middle = (upper.rect.maxY + lower.rect.minY) / 2
        let rect = CGRect(
          x: upper.rect.minX, y: middle - Metrics.Overview.dividerHitHeight / 2,
          width: upper.rect.width, height: Metrics.Overview.dividerHitHeight)
        return Divider(column: index, upper: upper.id, lower: lower.id, rect: rect)
      }
    }
  }

  func edge(at point: CGPoint) -> Edge? {
    edges.first { $0.rect.contains(point) }
  }

  func divider(at point: CGPoint) -> Divider? {
    dividers.first { $0.rect.contains(point) }
  }
}
