import SwiftUI

struct PreviewSection<Content: View>: View {
  let description: String
  var height = PreviewMetrics.sectionHeight
  @ViewBuilder let content: Content

  var body: some View {
    Section {
      content
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(description)
    }
  }
}
