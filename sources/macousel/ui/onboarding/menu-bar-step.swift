import SwiftUI

struct MenuBarStep: View {
  var body: some View {
    OnboardingStepLayout(
      hero: OnboardingHero(
        frames: OnboardingScenes.menuBar(), restingIndex: 4,
        description: "The pointer opens the Macousel menu in the menu bar and picks Settings"),
      title: "Find Macousel in the menu bar",
      subtitle: "Its menu holds everything else."
    ) {
      VStack(alignment: .leading, spacing: Metrics.Spacing.comfortable) {
        OnboardingFeatureRow(systemImage: "gearshape", title: "Settings for widths, gaps, and shortcuts")
        OnboardingFeatureRow(systemImage: "pause.circle", title: "Pause tiling for a normal desktop")
        OnboardingFeatureRow(systemImage: "arrow.counterclockwise", title: "Show this guide again")
      }
    }
  }
}
