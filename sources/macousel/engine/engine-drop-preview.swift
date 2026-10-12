import CoreGraphics
import StripCore

struct EngineDropPreview {
  let columns: EngineColumns
  let viewport: CGRect

  func frame(for target: DropTarget, dragging window: WindowID) -> CGRect? {
    switch target {
    case .nowhere: nil
    case .stack(let onto, let side): half(of: onto, side: side)
    case .column(let position): slot(at: position, dragging: window)
    }
  }

  private func half(of window: WindowID, side: VerticalNeighbor) -> CGRect? {
    guard let frame = columns.frame(of: window) else { return nil }
    let height = frame.height / 2
    return CGRect(
      x: frame.minX, y: side == .above ? frame.minY : frame.minY + height, width: frame.width,
      height: height)
  }

  private func slot(at position: Int, dragging window: WindowID) -> CGRect? {
    guard let size = columns.frame(of: window)?.size else { return nil }
    let spans = spans(excluding: window)
    guard let first = spans.first, let last = spans.last else { return nil }
    let width = min(size.width, viewport.width)
    let origin: CGFloat
    if position <= 0 {
      origin = first.lowerBound - width
    } else if position >= spans.count {
      origin = last.upperBound
    } else {
      origin = (spans[position - 1].upperBound + spans[position].lowerBound) / 2 - width / 2
    }
    let x = min(max(origin, viewport.minX), viewport.maxX - width)
    let extent = verticalExtent
    return CGRect(x: x, y: extent.lowerBound, width: width, height: extent.upperBound - extent.lowerBound)
  }

  private func spans(excluding window: WindowID) -> [ClosedRange<CGFloat>] {
    columns.windowIDs.compactMap { members in
      let frames = members.filter { $0 != window }.compactMap { columns.frame(of: $0) }
      guard let left = frames.map(\.minX).min(), let right = frames.map(\.maxX).max() else {
        return nil
      }
      return left...right
    }
  }

  private var verticalExtent: ClosedRange<CGFloat> {
    let frames = columns.windowIDs.flatMap { $0 }.compactMap { columns.frame(of: $0) }
    guard let top = frames.map(\.minY).min(), let bottom = frames.map(\.maxY).max() else {
      return viewport.minY...viewport.maxY
    }
    return top...bottom
  }
}
