import CoreGraphics
import Foundation

public struct DropRule: Sendable {
  public static let sideBandShare = 0.2
  public static let stackZoneShare = 1 - 2 * sideBandShare

  private struct ColumnSpan {
    var minX: CGFloat
    var maxX: CGFloat
  }

  private let strip: Strip
  private let dragged: WindowID
  private let frames: [(window: WindowID, rank: Int, frame: CGRect)]
  private let spans: [ColumnSpan]
  private let verticalExtent: ClosedRange<CGFloat>

  public init(strip: Strip, layout: StripLayout, viewport: CGRect, dragging window: WindowID) {
    self.strip = strip
    dragged = window
    let remaining = layout.placements.filter { $0.window != window }
    let columns = Set(remaining.map(\.column)).sorted()
    let rankOfColumn = Dictionary(uniqueKeysWithValues: columns.enumerated().map { ($1, $0) })
    frames = remaining.filter { !$0.isBehindTab }.compactMap { placement in
      rankOfColumn[placement.column].map { (placement.window, $0, placement.frame) }
    }
    spans = columns.map { column in
      let columnFrames = remaining.filter { $0.column == column }.map(\.frame)
      return ColumnSpan(
        minX: columnFrames.map(\.minX).min() ?? 0, maxX: columnFrames.map(\.maxX).max() ?? 0)
    }
    verticalExtent = viewport.minY...max(viewport.minY, viewport.maxY)
  }

  public func target(at point: CGPoint) -> DropTarget {
    let candidate = frameZone(at: point) ?? gapZone(at: point)
    guard candidate != .nowhere,
      applying(candidate).columns.map(\.windows) != strip.columns.map(\.windows)
    else { return .nowhere }
    return candidate
  }

  public func applying(_ target: DropTarget) -> Strip {
    Self.applying(target, moving: dragged, to: strip)
  }

  public static func applying(_ target: DropTarget, moving dragged: WindowID, to strip: Strip)
    -> Strip
  {
    var result = strip
    switch target {
    case .nowhere:
      break
    case .column(let position):
      result.move(dragged, toColumn: position)
    case .stack(let onto, let side):
      guard let destination = strip.location(of: onto), let source = strip.location(of: dragged)
      else { break }
      var row = side == .above ? destination.row : destination.row + 1
      if source.column == destination.column && source.row < destination.row { row -= 1 }
      result.stack(dragged, ontoColumnOf: onto, atRow: row)
    }
    return result
  }

  private func frameZone(at point: CGPoint) -> DropTarget? {
    guard
      let hit = frames.first(where: {
        $0.frame.minX <= point.x && point.x <= $0.frame.maxX && $0.frame.minY <= point.y
          && point.y <= $0.frame.maxY
      })
    else { return nil }
    let band = hit.frame.width * Self.sideBandShare
    if point.x < hit.frame.minX + band { return .column(position: hit.rank) }
    if point.x > hit.frame.maxX - band { return .column(position: hit.rank + 1) }
    return .stack(onto: hit.window, side: point.y < hit.frame.midY ? .above : .below)
  }

  private func gapZone(at point: CGPoint) -> DropTarget {
    guard verticalExtent.contains(point.y), let first = spans.first, let last = spans.last else {
      return .nowhere
    }
    if point.x < first.minX { return .column(position: 0) }
    if point.x > last.maxX { return .column(position: spans.count) }
    for index in spans.indices.dropLast() {
      if spans[index].maxX < point.x && point.x < spans[index + 1].minX {
        return .column(position: index + 1)
      }
    }
    return .nowhere
  }
}
