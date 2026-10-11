import CoreGraphics

public struct GrowthGate: Sendable, Equatable {
  public static let overlapTolerance: CGFloat = 2

  public struct Obstacle: Sendable, Equatable {
    public var frame: CGRect
    public var isParked: Bool

    public init(frame: CGRect, isParked: Bool) {
      self.frame = frame
      self.isParked = isParked
    }
  }

  public init() {}

  public func allowsGrowth(to candidate: CGRect, amid obstacles: [Obstacle]) -> Bool {
    !obstacles.contains { !$0.isParked && overlaps(candidate, $0.frame) }
  }

  private func overlaps(_ first: CGRect, _ second: CGRect) -> Bool {
    let horizontal = min(first.maxX, second.maxX) - max(first.minX, second.minX)
    let vertical = min(first.maxY, second.maxY) - max(first.minY, second.minY)
    return horizontal > Self.overlapTolerance && vertical > Self.overlapTolerance
  }
}
