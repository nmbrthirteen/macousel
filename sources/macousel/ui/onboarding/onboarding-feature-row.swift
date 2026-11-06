import SwiftUI

struct OnboardingFeatureRow: View {
  private static let iconWidth = 28.0

  let systemImage: String
  let title: String

  var body: some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: systemImage)
        .font(.title2)
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.tint)
        .frame(width: Self.iconWidth)
    }
  }
}
