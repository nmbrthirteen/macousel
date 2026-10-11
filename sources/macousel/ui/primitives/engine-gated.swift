import SwiftUI

struct EngineGated: ViewModifier {
  let isSupported: Bool

  func body(content: Content) -> some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
      content
        .disabled(!isSupported)
      if !isSupported {
        CaptionText(EngineFeature.unsupportedCaption)
      }
    }
  }
}

extension View {
  func engineGated(_ feature: EngineFeature, for engine: WindowEngine) -> some View {
    modifier(EngineGated(isSupported: feature.isSupported(by: engine)))
  }
}
