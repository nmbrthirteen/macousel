import CoreGraphics
import StripCore

struct EngineDropTargeting {
  let columns: EngineColumns
  let viewport: CGRect

  private struct Span {
    var rank: Int
    var column: EngineColumns.Column

    var minX: CGFloat { column.horizontalExtent?.lowerBound ?? 0 }
    var maxX: CGFloat { column.horizontalExtent?.upperBound ?? 0 }

    var frames: [(window: WindowID, frame: CGRect)] {
      column.windows.compactMap { member in
        guard let id = EngineWindowID.make(member.windowId), let frame = member.frame else {
          return nil
        }
        return (window: id, frame: frame.rect)
      }
    }
  }

  func target(dragging window: WindowID, at point: CGPoint) -> DropTarget {
    guard viewport.minX <= point.x, point.x <= viewport.maxX else { return .nowhere }
    let candidate = candidate(for: window, at: point)
    let current = strip
    let moved = DropRule.applying(candidate, moving: window, to: current)
    return moved.columns.map(\.windows) == current.columns.map(\.windows) ? .nowhere : candidate
  }

  private func candidate(for window: WindowID, at point: CGPoint) -> DropTarget {
    let visible = spans(excluding: window).filter { $0.column.isOnScreen(in: viewport) }
    if let hit = visible.first(where: { $0.minX <= point.x && point.x <= $0.maxX }) {
      return zone(in: hit, at: point)
    }
    if let next = visible.first(where: { $0.minX > point.x }) {
      return .column(position: next.rank)
    }
    guard let last = visible.last else { return .nowhere }
    return .column(position: last.rank + 1)
  }

  private func zone(in span: Span, at point: CGPoint) -> DropTarget {
    let band = (span.maxX - span.minX) * DropRule.sideBandShare
    if point.x < span.minX + band { return .column(position: span.rank) }
    if point.x > span.maxX - band { return .column(position: span.rank + 1) }
    let nearest = span.frames.min {
      abs($0.frame.midY - point.y) < abs($1.frame.midY - point.y)
    }
    guard let nearest else { return .nowhere }
    return .stack(onto: nearest.window, side: point.y < nearest.frame.midY ? .above : .below)
  }

  private func spans(excluding window: WindowID) -> [Span] {
    let remaining = columns.columns.map { column in
      let members = column.windows.filter {
        $0.frame != nil && EngineWindowID.make($0.windowId) != window
      }
      return EngineColumns.Column(windows: members)
    }
    return remaining.filter { !$0.windows.isEmpty }.enumerated().map { rank, column in
      Span(rank: rank, column: column)
    }
  }

  private var strip: Strip {
    var result = Strip()
    for column in columns.columns {
      let members = column.windowIDs
      guard let first = members.first else { continue }
      result.append(first, width: .fixed(column.width ?? 0))
      for (row, member) in members.enumerated().dropFirst() {
        result.append(member, width: .fixed(column.width ?? 0))
        result.stack(member, ontoColumnOf: first, atRow: row)
      }
    }
    return result
  }
}
