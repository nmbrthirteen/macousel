import SwiftUI

struct OnboardingFooter: View {
  private static let transition = Animation.smooth(duration: 0.35)

  let flow: OnboardingFlow

  var body: some View {
    ZStack {
      OnboardingPageDots(current: flow.step.rawValue, count: OnboardingFlow.Step.allCases.count)
      buttons
    }
    .padding(.horizontal, OnboardingMetrics.contentInset)
    .padding(.top, Metrics.Spacing.comfortable)
    .padding(.bottom, Metrics.Spacing.spacious)
  }

  private var buttons: some View {
    HStack {
      Button("Back") { withAnimation(Self.transition, flow.goBack) }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .keyboardShortcut(.cancelAction)
        .opacity(flow.canGoBack ? 1 : 0)
        .disabled(!flow.canGoBack)
      Spacer()
      Button(flow.continueTitle) { withAnimation(Self.transition, flow.advance) }
        .buttonStyle(ContinueButtonStyle())
        .keyboardShortcut(.defaultAction)
    }
  }
}
