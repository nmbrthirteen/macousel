import SwiftUI

struct OnboardingView: View {
  let store: PreferencesStore
  let flow: OnboardingFlow
  @State private var accessibility = AccessibilityStatus()

  var body: some View {
    VStack(spacing: Metrics.Spacing.roomy) {
      stepContent
      OnboardingFooter(flow: flow)
    }
    .padding(Metrics.Spacing.spacious)
    .frame(width: Metrics.Size.onboardingWidth, height: Metrics.Size.onboardingHeight)
  }

  @ViewBuilder
  private var stepContent: some View {
    switch flow.step {
    case .howItWorks: HowItWorksStep()
    case .accessibility: AccessStep(status: accessibility)
    case .shortcuts: StarterShortcutsStep(store: store)
    }
  }
}
