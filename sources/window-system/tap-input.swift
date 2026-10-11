import CoreGraphics
import Foundation

nonisolated enum TapInput {
  case scroll(
    flags: CGEventFlags, momentumPhase: Int64, scrollPhase: Int64, horizontalDelta: Double,
    verticalDelta: Double)
  case mouse(kind: TapMouseEvent.Kind, location: CGPoint, timestamp: TimeInterval)
}
