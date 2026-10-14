import SwiftUI

struct WelcomeStep: View {
  let preferences: Preferences

  var body: some View {
    OnboardingStepLayout(
      hero: OnboardingHero(
        frames: OnboardingScenes.welcome(keys: preferences.primaryKeys(for:)),
        description: "A strip of windows slides to follow focus as shortcuts are pressed"),
      title: "Your windows, on one strip",
      subtitle: "Windows line up as columns. The strip scrolls to follow focus."
    ) {
      VStack(alignment: .leading, spacing: Metrics.Spacing.comfortable) {
        OnboardingFeatureRow(systemImage: "rectangle.split.3x1", title: "New windows open as columns")
        OnboardingFeatureRow(systemImage: "keyboard", title: "Move around with shortcuts")
        OnboardingFeatureRow(systemImage: "square.stack", title: "Drag a window onto another to stack")
      }
    }
  }
}
