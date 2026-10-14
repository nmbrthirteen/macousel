import SwiftUI

struct ContinueButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(.background)
      .padding(.horizontal, OnboardingMetrics.continueHorizontalPadding)
      .padding(.vertical, OnboardingMetrics.continueVerticalPadding)
      .background(
        .primary,
        in: RoundedRectangle(cornerRadius: OnboardingMetrics.continueRadius, style: .continuous)
      )
      .opacity(configuration.isPressed || !isEnabled ? OnboardingMetrics.pressedOpacity : 1)
      .contentShape(Rectangle())
  }
}
