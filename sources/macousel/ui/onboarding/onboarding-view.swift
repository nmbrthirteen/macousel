import SwiftUI

struct OnboardingView: View {
  // Taller than the shared metric by the gap between the scene and the title.
  static let size = CGSize(
    width: OnboardingMetrics.width, height: OnboardingMetrics.height + Metrics.Spacing.roomy)

  let store: PreferencesStore
  let flow: OnboardingFlow
  let onSkip: () -> Void
  @State private var accessibility = AccessibilityStatus()

  var body: some View {
    VStack(spacing: 0) {
      stepContent
        .id(flow.step)
        .transition(.opacity)
      OnboardingFooter(flow: flow, onSkip: onSkip)
    }
    .frame(width: Self.size.width, height: Self.size.height)
    .onAppear {
      AccessibilityGuide.shared.onGranted = { [flow] in
        if flow.step == .accessibility { flow.advance() }
      }
    }
    .onDisappear {
      AccessibilityGuide.shared.onGranted = nil
      AccessibilityGuide.shared.cancel()
    }
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
