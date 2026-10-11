import StripCore
import SwiftUI

struct WelcomeStripPreview: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var loop = FocusLoop(
    restingColumn: PreviewMetrics.Sample.motionRestingColumn,
    alternateColumn: PreviewMetrics.Sample.motionAlternateColumn,
    interval: PreviewMetrics.Timing.motionInterval)

  var body: some View {
    OnboardingForm(height: OnboardingMetrics.previewHeight) {
      PreviewSection(description: PreviewDescription.welcome) {
        StripPreview(
          scenario: PreviewScenarios.motion(focusTrail: loop.trail).withLeadingColumns(
            PreviewMetrics.Sample.motionLeadingColumns,
            width: .fraction(PreviewMetrics.Sample.motionColumnWidth)),
          config: LayoutConfig(),
          animation: PreviewAnimation.curve(for: .fast, reduceMotion: reduceMotion))
          .onAppear { loop.start(reduceMotion: reduceMotion) }
          .onDisappear(perform: loop.stop)
          .onChange(of: reduceMotion) { loop.start(reduceMotion: reduceMotion) }
      }
    }
  }
}
