import SwiftUI

struct OverviewPlaceholderView: View {
  let rect: CGRect

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Metrics.Radius.panel)
  }

  var body: some View {
    shape
      .fill(Color.accentColor.opacity(Metrics.Overview.placeholderFill))
      .overlay {
        shape.strokeBorder(
          Color.accentColor.opacity(Metrics.Overview.placeholderStroke),
          style: StrokeStyle(
            lineWidth: Metrics.Overview.selectionStroke / 2,
            dash: [Metrics.Overview.placeholderDash]))
      }
      .frame(width: rect.width, height: rect.height)
      .offset(x: rect.minX, y: rect.minY)
      .allowsHitTesting(false)
  }
}
