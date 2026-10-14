import SwiftUI

struct OnboardingStepLayout<Content: View>: View {
  let hero: OnboardingHero
  let title: String
  let subtitle: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      hero
      VStack(alignment: .leading, spacing: Metrics.Spacing.spacious) {
        VStack(alignment: .leading, spacing: Metrics.Spacing.compact) {
          Text(title)
            .font(.title.weight(.semibold))
          Text(subtitle)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        content
      }
      .padding(.horizontal, OnboardingMetrics.contentInset)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
