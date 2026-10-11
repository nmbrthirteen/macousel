import CoreGraphics
import StripCore

struct PlannedFrame {
  var window: CGWindowID
  var placement: Placement
  var target: CGRect
  var previous: CGRect?
  var isParked: Bool

  var isGrowing: Bool {
    guard let previous, !isParked else { return false }
    return target.width > previous.width || target.height > previous.height
  }

  var heldFrame: CGRect {
    CGRect(origin: target.origin, size: previous?.size ?? target.size)
  }
}
