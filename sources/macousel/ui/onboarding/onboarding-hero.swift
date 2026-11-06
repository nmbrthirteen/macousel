import SwiftUI

struct OnboardingHero: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.controlActiveState) private var activeState
  @State private var start = Date.now
  @State private var isWindowVisible = true
  let timeline: SceneTimeline
  let description: String

  init(frames: [SceneFrame], restingIndex: Int = 0, description: String) {
    timeline = SceneTimeline(frames: frames, restingIndex: restingIndex)
    self.description = description
  }

  private var isPaused: Bool {
    reduceMotion || activeState != .key || !isWindowVisible
  }

  var body: some View {
    // Redraws every frame, so it stops unless the window is key and on screen.
    TimelineView(.animation(paused: isPaused)) { context in
      SceneDesktop(
        pose: reduceMotion
          ? timeline.restingPose : timeline.pose(at: context.date.timeIntervalSince(start)))
    }
    .readsWindowVisibility($isWindowVisible)
    .accessibilityElement()
    .accessibilityLabel(description)
  }
}
