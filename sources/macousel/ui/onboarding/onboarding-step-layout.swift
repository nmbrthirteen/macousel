import SwiftUI

struct OnboardingStepLayout<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.roomy) {
      Text(title)
        .font(.title2.bold())
      content
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
