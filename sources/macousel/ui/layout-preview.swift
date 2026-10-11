import StripCore
import SwiftUI

struct LayoutPreview: View {
  let config: LayoutConfig
  let animationSpeed: AnimationSpeed
  let hoveredPreset: Double?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var loop = FocusLoop(
    restingColumn: PreviewMetrics.Sample.layoutRestingColumn,
    alternateColumn: PreviewMetrics.Sample.layoutAlternateColumn,
    interval: PreviewMetrics.Timing.layoutInterval)

  var body: some View {
    PreviewSection(description: PreviewDescription.layout(config)) {
      StripPreview(
        scenario: PreviewScenarios.layout(
          config: config, focusTrail: loop.trail, hoveredPreset: hoveredPreset
        ).withLeadingColumns(
          StripPreviewScenario.leadingColumnCount(forWidth: config.defaultWidth),
          width: .fraction(config.defaultWidth)),
        config: config,
        animation: PreviewAnimation.curve(for: animationSpeed, reduceMotion: reduceMotion))
        .onAppear { loop.start(reduceMotion: reduceMotion) }
        .onDisappear(perform: loop.stop)
        .onChange(of: reduceMotion) { loop.start(reduceMotion: reduceMotion) }
    }
  }
}
