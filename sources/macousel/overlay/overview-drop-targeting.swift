import CoreGraphics
import StripCore

struct OverviewDropTargeting {
  let snapshot: OverviewSnapshot
  let geometry: OverviewGeometry

  func target(dragging window: WindowID, at point: CGPoint) -> DropTarget {
    DropRule(
      strip: snapshot.makeStrip(), layout: geometry.dropLayout, viewport: geometry.stripBounds,
      dragging: window
    ).target(at: point)
  }
}
