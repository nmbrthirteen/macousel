import CoreGraphics
import StripCore

struct SwipeDiagram: Equatable {
  let fingerCount: Int
  let reversesDirection: Bool

  var fingerDirection: HorizontalDirection { .left }

  var stripDirection: HorizontalDirection {
    reversesDirection ? .right : .left
  }

  var stripCaption: String {
    stripDirection == .left ? "The strip moves left" : "The strip moves right"
  }

  var fingerCenters: [CGPoint] {
    let middle = Double(fingerCount - 1) / 2
    return (0..<fingerCount).map { index in
      let offset = Double(index) - middle
      return CGPoint(
        x: 0.5 + offset * PreviewMetrics.Trackpad.fingerSpacing,
        y: PreviewMetrics.Trackpad.fingerRestingY
          + abs(offset) * PreviewMetrics.Trackpad.fingerArcDepth)
    }
  }

  func scrollOffset(progress: Double, sensitivity: Double, usableWidth: Double) -> Double {
    let sign: Double = stripDirection == .left ? 1 : -1
    let travel =
      PreviewMetrics.Swipe.padShare * usableWidth * PreviewMetrics.Swipe.travelPerPadWidth
      * sensitivity
    return PreviewMetrics.Swipe.startOffset + sign * progress * travel
  }
}
