import StripCore
import SwiftUI

struct MotionPreview: View {
  let preferences: Preferences
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var loop = FocusLoop(
    restingColumn: PreviewMetrics.Sample.motionRestingColumn,
    alternateColumn: PreviewMetrics.Sample.motionAlternateColumn,
    interval: PreviewMetrics.Timing.motionInterval)

  private var decoration: StripPreviewDecoration {
    StripPreviewDecoration(
      focusBorderWidth: preferences.showsFocusBorder ? preferences.focusBorderWidth : nil,
      dimAmount: preferences.dimsInactiveWindows ? preferences.dimAmount : nil)
  }

  var body: some View {
    PreviewSection(description: PreviewDescription.motion(preferences)) {
      VStack(spacing: PreviewMetrics.captionSpacing) {
        StripPreview(
          scenario: PreviewScenarios.motion(focusTrail: loop.trail), config: preferences.layout,
          decoration: decoration,
          animation: PreviewAnimation.spring(for: preferences.animationSpeed, reduceMotion: reduceMotion))
        if reduceMotion {
          CaptionText("Reduce Motion is on, so animations are off.")
        }
      }
      .onAppear { loop.start(reduceMotion: reduceMotion) }
      .onDisappear(perform: loop.stop)
      .onChange(of: reduceMotion) { loop.start(reduceMotion: reduceMotion) }
    }
  }
}
