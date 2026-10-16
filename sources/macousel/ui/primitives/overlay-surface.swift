import SwiftUI

struct OverlaySurface<S: InsettableShape>: ViewModifier {
  let shape: S
  var tint: Color?
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  @ViewBuilder
  func body(content: Content) -> some View {
    if reduceTransparency {
      content.background(tint ?? Color(nsColor: .windowBackgroundColor), in: shape)
    } else if #available(macOS 26, *) {
      content.glassEffect(.regular.tint(tint), in: shape)
    } else {
      content
        .background(tint?.opacity(0.25) ?? .clear, in: shape)
        .background(.regularMaterial, in: shape)
    }
  }
}

extension View {
  func overlaySurface<S: InsettableShape>(in shape: S, tint: Color? = nil) -> some View {
    modifier(OverlaySurface(shape: shape, tint: tint))
  }
}
