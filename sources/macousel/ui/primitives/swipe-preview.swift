import StripCore
import SwiftUI

struct SwipePreview: View {
  let diagram: SwipeDiagram
  let progress: Double
  let sensitivity: Double
  let config: LayoutConfig
  var animation: Animation?

  private var usableWidth: Double {
    PreviewMetrics.screenSize.width - 2 * config.outerGap
  }

  private var scenario: StripPreviewScenario {
    PreviewScenarios.swipe(
      scrollOffset: diagram.scrollOffset(
        progress: progress, sensitivity: sensitivity, usableWidth: usableWidth))
  }

  var body: some View {
    VStack(spacing: PreviewMetrics.Trackpad.rowSpacing) {
      TrackpadDiagram(diagram: diagram, progress: progress)
        .animation(animation, value: progress)
      HStack(spacing: Metrics.Spacing.regular) {
        PreviewArrowView(direction: diagram.stripDirection)
          .frame(
            width: PreviewMetrics.Trackpad.stripArrowReach,
            height: PreviewMetrics.Trackpad.stripArrowHeight)
        Text(diagram.stripCaption)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      StripPreview(scenario: scenario, config: config, animation: animation)
    }
  }
}
