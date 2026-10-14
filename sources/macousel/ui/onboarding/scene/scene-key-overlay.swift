import SwiftUI

struct SceneKeyOverlay: View {
  private static let fontSize = 22.0
  private static let horizontalPadding = 16.0
  private static let verticalPadding = 8.0
  private static let radius = 12.0
  private static let centerY = 150.0
  private static let enteringScale = 0.9

  let keys: String
  let visibility: Double

  var body: some View {
    Text(keys)
      .font(.system(size: Self.fontSize, weight: .semibold, design: .rounded))
      .foregroundStyle(.white)
      .padding(.horizontal, Self.horizontalPadding)
      .padding(.vertical, Self.verticalPadding)
      .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
      .scaleEffect(Self.enteringScale.mixed(with: 1, by: visibility))
      .opacity(visibility)
      .position(x: OnboardingSceneMetrics.size.width / 2, y: Self.centerY)
  }
}
