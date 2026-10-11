import SwiftUI

struct TrackpadDiagram: View {
  let diagram: SwipeDiagram
  let progress: Double

  private var size: CGSize {
    CGSize(
      width: PreviewMetrics.Trackpad.height * PreviewMetrics.Trackpad.aspect,
      height: PreviewMetrics.Trackpad.height)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: PreviewMetrics.Trackpad.cornerRadius, style: .continuous)
        .strokeBorder(
          Color.primary.opacity(PreviewMetrics.outlineOpacity),
          lineWidth: PreviewMetrics.outlineWidth)
      ForEach(Array(diagram.fingerCenters.enumerated()), id: \.offset) { _, center in
        Circle()
          .fill(Color.accentColor)
          .frame(
            width: PreviewMetrics.Trackpad.fingerDiameter,
            height: PreviewMetrics.Trackpad.fingerDiameter)
          .position(
            x: (center.x - progress * PreviewMetrics.Trackpad.fingerTravel) * size.width,
            y: center.y * size.height)
      }
      PreviewArrowView(direction: diagram.fingerDirection)
        .frame(width: size.width * PreviewMetrics.Trackpad.arrowReach, height: 12)
        .position(x: size.width / 2, y: size.height * PreviewMetrics.Trackpad.arrowY)
    }
    .frame(width: size.width, height: size.height)
  }
}
