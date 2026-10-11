import StripCore
import SwiftUI
import WindowSystem

struct DisplaysPreview: View {
  let displays: [Display]
  let disabled: Set<String>
  let config: LayoutConfig
  let animationSpeed: AnimationSpeed
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    PreviewSection(description: PreviewDescription.displays(displays, disabled: disabled)) {
      DisplayDrawing(
        displays: displays, disabled: disabled, config: config,
        animation: PreviewAnimation.spring(for: animationSpeed, reduceMotion: reduceMotion))
    }
  }
}
