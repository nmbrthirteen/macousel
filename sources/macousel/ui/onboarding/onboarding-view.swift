import SwiftUI

struct OnboardingView: View {
  let store: PreferencesStore
  let flow: OnboardingFlow
  @State private var accessibility = AccessibilityStatus()

  var body: some View {
    VStack(spacing: 0) {
      stepContent
        .id(flow.step)
        .transition(.opacity)
      OnboardingFooter(flow: flow)
    }
    .frame(width: OnboardingMetrics.width, height: OnboardingMetrics.height)
    .background(.background)
    .ignoresSafeArea()
  }

  @ViewBuilder
  private var stepContent: some View {
    switch flow.step {
    case .howItWorks: WelcomeStep(preferences: store.preferences)
    case .accessibility: AccessStep(preferences: store.preferences, status: accessibility)
    case .shortcuts: StarterShortcutsStep(preferences: store.preferences)
    case .menuBar: MenuBarStep()
    }
  }
}
