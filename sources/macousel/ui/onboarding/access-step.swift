import SwiftUI
import WindowSystem

struct AccessStep: View {
  let status: AccessibilityStatus

  var body: some View {
    OnboardingStepLayout(title: "Allow Accessibility access") {
      Text("Macousel needs this permission to move and resize your windows.")
      OnboardingForm(height: OnboardingMetrics.accessHeight) {
        AccessibilityStatusRow(
          status: status,
          grant: .init(title: "Grant access", perform: AccessibilityPermission.requestWithPrompt)
        )
      }
    }
  }
}
