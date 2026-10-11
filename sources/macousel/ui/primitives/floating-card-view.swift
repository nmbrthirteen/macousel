import SwiftUI

struct FloatingCardView: View {
  let rect: CGRect

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: PreviewMetrics.windowCornerRadius, style: .continuous)
  }

  var body: some View {
    shape
      .fill(Color(nsColor: .windowBackgroundColor))
      .overlay(alignment: .top) {
        Rectangle()
          .fill(Color.primary.opacity(PreviewMetrics.unfocusedWindowOpacity))
          .frame(height: rect.height * PreviewMetrics.cardTitleBarHeight)
          .clipShape(shape)
      }
      .overlay {
        shape.strokeBorder(
          Color.primary.opacity(PreviewMetrics.outlineOpacity), lineWidth: Metrics.Size.hairlineStroke)
      }
      .shadow(
        color: .black.opacity(PreviewMetrics.cardShadowOpacity),
        radius: PreviewMetrics.cardShadowRadius, y: 1)
      .frame(width: rect.width, height: rect.height)
      .offset(x: rect.minX, y: rect.minY)
  }
}
