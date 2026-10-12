import CoreGraphics
import StripCore

struct EngineDropTargeting {
  let columns: EngineColumns
  let viewport: CGRect

  private struct Span {
    var rank: Int
    var frames: [(window: WindowID, frame: CGRect)]

    var minX: CGFloat { frames.map(\.frame.minX).min() ?? 0 }
    var maxX: CGFloat { frames.map(\.frame.maxX).max() ?? 0 }
  }

  func target(dragging window: WindowID, at point: CGPoint) -> DropTarget {
    guard viewport.minX <= point.x, point.x <= viewport.maxX else { return .nowhere }
    let candidate = candidate(for: window, at: point)
    let current = strip
    let moved = DropRule.applying(candidate, moving: window, to: current)
    return moved.columns.map(\.windows) == current.columns.map(\.windows) ? .nowhere : candidate
  }

  private func candidate(for window: WindowID, at point: CGPoint) -> DropTarget {
    let visible = spans(excluding: window).filter {
      $0.maxX > viewport.minX && $0.minX < viewport.maxX
    }
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
    let remaining = columns.windowIDs.map { members in
      members.filter { $0 != window }.compactMap { member in
        columns.frame(of: member).map { (window: member, frame: $0) }
      }
    }
    return remaining.filter { !$0.isEmpty }.enumerated().map { Span(rank: $0, frames: $1) }
  }

  private var strip: Strip {
    var result = Strip()
    for column in columns.columns {
      let members = column.windowIDs
      guard let first = members.first else { continue }
      result.append(first, width: .fixed(column.width ?? 0))
      for (row, member) in members.enumerated().dropFirst() {
        result.stack(member, ontoColumnOf: first, atRow: row)
      }
    }
    return result
  }
}
