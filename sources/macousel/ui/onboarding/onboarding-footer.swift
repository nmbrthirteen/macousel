import SwiftUI

struct OnboardingFooter: View {
  let flow: OnboardingFlow

  var body: some View {
    HStack {
      Button("Back", action: flow.goBack)
        .actionButtonStyle(.secondary)
        .disabled(!flow.canGoBack)
      Spacer()
      Button(flow.continueTitle, action: flow.advance)
        .actionButtonStyle(.primary)
        .keyboardShortcut(.defaultAction)
    }
  }
}
