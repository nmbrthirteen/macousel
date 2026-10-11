import SwiftUI

struct OverlaySurface<S: InsettableShape>: ViewModifier {
  let shape: S
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  @ViewBuilder
  func body(content: Content) -> some View {
    if reduceTransparency {
      content.background(Color(nsColor: .windowBackgroundColor), in: shape)
    } else {
      content.glassEffect(.regular, in: shape)
    }
  }
}

extension View {
  func overlaySurface<S: InsettableShape>(in shape: S) -> some View {
    modifier(OverlaySurface(shape: shape))
  }
}
