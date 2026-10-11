import SwiftUI

struct HowItWorksStep: View {
  var body: some View {
    OnboardingStepLayout(title: "How Macousel works") {
      Text(
        "Your windows sit side by side as columns on one horizontal strip. The strip is wider than your screen, so it scrolls."
      )
      WelcomeStripPreview()
      CaptionText("The focused column stays in view. Move focus and the strip slides to follow.")
    }
  }
}
