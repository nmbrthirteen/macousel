import SwiftUI
import WindowSystem

struct AccessStep: View {
  let status: AccessibilityStatus

  var body: some View {
    OnboardingStepLayout(title: "Allow Accessibility access") {
      Text(
        "macOS only lets an app move other apps' windows through the Accessibility API. Macousel needs this permission to place your windows."
      )
      Form {
        AccessibilityStatusRow(
          status: status,
          grant: .init(title: "Grant access", perform: AccessibilityPermission.requestWithPrompt)
        )
      }
      .formStyle(.grouped)
      .scrollDisabled(true)
    }
  }
}
