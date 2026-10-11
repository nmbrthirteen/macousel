import SwiftUI

struct OnboardingForm<Content: View>: View {
  var height: CGFloat?
  @ViewBuilder let content: Content

  var body: some View {
    Form {
      content
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
    .scrollContentBackground(.hidden)
    .padding(-OnboardingMetrics.formInset)
    .frame(height: height)
  }
}
