import Foundation

public enum SwipeIntent: Sendable, Equatable {
  case none, backward, forward

  public static let travelShare = 0.12
  public static let flickSpeed = 400.0

  public init(travel: Double, velocity: Double, usableWidth: Double) {
    if abs(velocity) > Self.flickSpeed {
      self = velocity > 0 ? .forward : .backward
    } else if travel != 0, abs(travel) >= Self.travelShare * usableWidth {
      self = travel > 0 ? .forward : .backward
    } else {
      self = .none
    }
  }

  public func restingIndex(among anchors: [Double], from start: Double, projected: Double)
    -> Int?
  {
    guard let last = anchors.indices.last else { return nil }
    let projectedIndex = Self.nearest(in: anchors, to: projected)
    let startIndex = Self.nearest(in: anchors, to: start)
    switch self {
    case .none: return projectedIndex
    case .forward: return min(max(projectedIndex, startIndex + 1), last)
    case .backward: return max(min(projectedIndex, startIndex - 1), 0)
    }
  }

  private static func nearest(in anchors: [Double], to offset: Double) -> Int {
    anchors.indices.min { abs(anchors[$0] - offset) < abs(anchors[$1] - offset) } ?? 0
  }
}
