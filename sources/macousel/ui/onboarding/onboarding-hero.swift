import SwiftUI

struct OnboardingHero: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var start = Date.now
  let timeline: SceneTimeline
  let description: String

  init(frames: [SceneFrame], restingIndex: Int = 0, description: String) {
    timeline = SceneTimeline(frames: frames, restingIndex: restingIndex)
    self.description = description
  }

  var body: some View {
    TimelineView(.animation(paused: reduceMotion)) { context in
      SceneDesktop(
        pose: reduceMotion
          ? timeline.restingPose : timeline.pose(at: context.date.timeIntervalSince(start)))
    }
    .mask {
      LinearGradient(
        stops: [
          .init(color: .black, location: OnboardingMetrics.heroFadeStart),
          .init(color: .clear, location: 1),
        ],
        startPoint: .top, endPoint: .bottom)
    }
    .accessibilityElement()
    .accessibilityLabel(description)
  }
}
