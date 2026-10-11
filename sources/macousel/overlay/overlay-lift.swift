import SwiftUI

struct OverlayLift: ViewModifier {
  let isLifted: Bool
  let scale: Double
  let shadowRadius: Double

  func body(content: Content) -> some View {
    content
      .scaleEffect(isLifted ? scale : 1)
      .shadow(
        color: .black.opacity(isLifted ? Metrics.Overlay.liftShadowOpacity : 0),
        radius: shadowRadius, y: Metrics.Spacing.compact)
  }
}

extension View {
  func overlayLift(_ isLifted: Bool, scale: Double, shadowRadius: Double) -> some View {
    modifier(OverlayLift(isLifted: isLifted, scale: scale, shadowRadius: shadowRadius))
  }
}
