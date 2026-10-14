import SwiftUI

struct AccessStep: View {
  let preferences: Preferences
  let status: AccessibilityStatus

  var body: some View {
    OnboardingStepLayout(
      hero: OnboardingHero(
        frames: OnboardingScenes.access(keys: preferences.primaryKeys(for:)), restingIndex: 4,
        description: "Accessibility is switched on for Macousel and loose windows line up into a strip"),
      title: "Allow Accessibility",
      subtitle: "Macousel needs it to move and resize your windows."
    ) {
      VStack(alignment: .leading, spacing: Metrics.Spacing.comfortable) {
        OnboardingFeatureRow(systemImage: "switch.2", title: "Turn on Macousel in System Settings")
        OnboardingFeatureRow(systemImage: "arrow.uturn.backward", title: "Come back here to continue")
        AccessibilityGrantLine(status: status)
          .padding(.top, Metrics.Spacing.tight)
      }
    }
  }
}
