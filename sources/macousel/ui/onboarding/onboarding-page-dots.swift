import SwiftUI

struct OnboardingPageDots: View {
  private static let diameter = 6.0

  let current: Int
  let count: Int

  var body: some View {
    HStack(spacing: Metrics.Spacing.compact) {
      ForEach(0..<count, id: \.self) { index in
        Circle()
          .fill(index == current ? AnyShapeStyle(.primary) : AnyShapeStyle(.quaternary))
          .frame(width: Self.diameter, height: Self.diameter)
      }
    }
    .accessibilityElement()
    .accessibilityLabel("Step \(current + 1) of \(count)")
  }
}
