import SwiftUI

struct OnboardingFooter: View {
  private static let transition = Animation.easeInOut(duration: 0.2)

  let flow: OnboardingFlow
  let onSkip: () -> Void

  var body: some View {
    HStack {
      if !flow.isLastStep {
        Button("Skip guide", action: onSkip)
          .keyboardShortcut(.cancelAction)
      }
      Spacer()
      if flow.canGoBack {
        Button("Back") { withAnimation(Self.transition, flow.goBack) }
      }
      Button(flow.continueTitle) { withAnimation(Self.transition, flow.advance) }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
    }
    .padding(.horizontal, OnboardingMetrics.contentInset)
    .padding(.top, Metrics.Spacing.comfortable)
    .padding(.bottom, Metrics.Spacing.spacious)
  }
}
