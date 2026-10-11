import SwiftUI

struct HowItWorksStep: View {
  var body: some View {
    OnboardingStepLayout(title: "How Macousel works") {
      Text(
        "Every window is a column on one horizontal strip. The strip is wider than your screen, so it scrolls."
      )
      StripIllustration()
      Text("The focused column stays in view. Move focus, and the strip slides to follow.")
    }
  }
}
