import SwiftUI

// Sits as the first row of the section it illustrates, inset like the rows around it.
struct PreviewCard<Content: View>: View {
  let description: String
  var height = PreviewMetrics.sectionHeight
  @ViewBuilder let content: Content

  var body: some View {
    content
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(description)
  }
}
