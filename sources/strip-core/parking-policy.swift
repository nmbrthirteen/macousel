import CoreGraphics

public struct ParkingPolicy: Sendable, Equatable {
  public static let visibleSliver: CGFloat = 1

  public var displayBounds: CGRect
  public var hasLeftNeighbor: Bool
  public var hasRightNeighbor: Bool

  public init(displayBounds: CGRect, hasLeftNeighbor: Bool, hasRightNeighbor: Bool) {
    self.displayBounds = displayBounds
    self.hasLeftNeighbor = hasLeftNeighbor
    self.hasRightNeighbor = hasRightNeighbor
  }

  public func frame(for placement: Placement, in viewport: CGRect) -> CGRect {
    switch placement.visibility {
    case .full:
      return placement.frame
    case .partial:
      let side = overhangSide(of: placement.frame, in: viewport)
      return hasNeighbor(on: side) && overhangsPastHalf(placement.frame, toward: side)
        ? parked(placement.frame, toward: side) : placement.frame
    case .offscreen(let side):
      return parked(placement.frame, toward: side)
    }
  }

  public func parkedFrame(_ frame: CGRect, toward side: HorizontalDirection) -> CGRect {
    parked(frame, toward: side)
  }

  public func isParked(_ placement: Placement, in viewport: CGRect) -> Bool {
    frame(for: placement, in: viewport) != placement.frame
  }

  private func overhangSide(of frame: CGRect, in viewport: CGRect) -> HorizontalDirection {
    frame.minX < viewport.minX ? .left : .right
  }

  private func overhangsPastHalf(_ frame: CGRect, toward side: HorizontalDirection) -> Bool {
    let overhang = side == .left ? displayBounds.minX - frame.minX : frame.maxX - displayBounds.maxX
    return overhang > frame.width / 2
  }

  private func hasNeighbor(on side: HorizontalDirection) -> Bool {
    side == .left ? hasLeftNeighbor : hasRightNeighbor
  }

  private func parked(_ frame: CGRect, toward side: HorizontalDirection) -> CGRect {
    CGRect(origin: parkingOrigin(for: frame, toward: side), size: frame.size)
  }

  private func parkingOrigin(for frame: CGRect, toward side: HorizontalDirection) -> CGPoint {
    let beyondLeftEdge = CGPoint(
      x: displayBounds.minX + Self.visibleSliver - frame.width, y: frame.minY)
    let beyondRightEdge = CGPoint(x: displayBounds.maxX - Self.visibleSliver, y: frame.minY)
    let belowBottomEdge = CGPoint(x: frame.minX, y: displayBounds.maxY - Self.visibleSliver)

    switch (side, hasLeftNeighbor, hasRightNeighbor) {
    case (.left, false, _): return beyondLeftEdge
    case (.right, _, false): return beyondRightEdge
    case (.left, true, false): return beyondRightEdge
    case (.right, false, true): return beyondLeftEdge
    default: return belowBottomEdge
    }
  }
}
