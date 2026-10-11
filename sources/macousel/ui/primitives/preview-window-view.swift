import SwiftUI

struct PreviewWindowView: View {
  let window: PreviewWindow
  let decoration: StripPreviewDecoration
  let borderWidth: Double?

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: PreviewMetrics.windowCornerRadius, style: .continuous)
  }

  var body: some View {
    shape
      .fill(fill)
      .overlay { dimming }
      .overlay { focusBorder }
      .frame(width: window.rect.width, height: window.rect.height)
      .offset(x: window.rect.minX, y: window.rect.minY)
  }

  private var fill: Color {
    guard window.isFocused else { return Color.primary.opacity(PreviewMetrics.unfocusedWindowOpacity) }
    return borderWidth == nil
      ? Color.accentColor : Color.accentColor.opacity(PreviewMetrics.borderedFocusFill)
  }

  @ViewBuilder
  private var dimming: some View {
    if !window.isFocused, let amount = decoration.dimAmount {
      shape.fill(Color.black.opacity(amount))
    }
  }

  @ViewBuilder
  private var focusBorder: some View {
    if window.isFocused, let borderWidth {
      shape.strokeBorder(Color.accentColor, lineWidth: borderWidth)
    }
  }
}
