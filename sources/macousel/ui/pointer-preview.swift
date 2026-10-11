import SwiftUI

struct PointerPreview: View {
  let preferences: Preferences
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var demo = SwipeDemo()

  private var diagram: SwipeDiagram {
    SwipeDiagram(
      fingerCount: preferences.swipeFingers, reversesDirection: preferences.reversesSwipeDirection)
  }

  var body: some View {
    PreviewSection(
      description: PreviewDescription.swipe(
        fingers: preferences.swipeFingers, reversed: preferences.reversesSwipeDirection,
        sensitivity: preferences.swipeSensitivity),
      height: PreviewMetrics.swipeSectionHeight
    ) {
      SwipePreview(
        diagram: diagram, progress: demo.progress, sensitivity: preferences.swipeSensitivity,
        config: preferences.layout,
        animation: reduceMotion ? nil : .easeInOut(duration: PreviewMetrics.Timing.swipeDuration)
      )
      .onAppear { replay(after: .zero) }
      .onDisappear(perform: demo.stop)
      .onChange(of: preferences.swipeSensitivity) { replay(after: PreviewMetrics.Timing.swipeDebounce) }
      .onChange(of: preferences.reversesSwipeDirection) { replay(after: .zero) }
      .onChange(of: reduceMotion) { replay(after: .zero) }
    }
  }

  private func replay(after delay: Duration) {
    demo.replay(after: delay, reduceMotion: reduceMotion)
  }
}
