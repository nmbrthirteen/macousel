import SwiftUI

struct MenuBarLabelView: View {
  let presentation: MenuBarPresentation

  var body: some View {
    content
      .accessibilityLabel(presentation.accessibilityLabel)
  }

  @ViewBuilder
  private var content: some View {
    switch presentation.content {
    case .symbol(let name):
      Image(systemName: name)
    case .pills(let position):
      if let geometry = MenuBarPillGeometry(position: position) {
        Image(nsImage: MenuBarPillImage.make(geometry))
      }
    case .symbolWithCount(let symbol, let text):
      HStack(spacing: Metrics.Spacing.tight) {
        Image(systemName: symbol)
        Text(text).monospacedDigit()
      }
    }
  }
}
