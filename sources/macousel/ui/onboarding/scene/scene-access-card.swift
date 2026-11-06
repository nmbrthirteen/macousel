import AppKit
import SwiftUI

struct SceneAccessCard: View {
  private typealias Scene = OnboardingSceneMetrics
  private static let radius = 12.0
  private static let iconSide = 18.0
  private static let enteringScale = 0.96

  let visibility: Double
  let toggle: Double

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
      Text("Accessibility")
        .font(.callout.weight(.semibold))
      Text("Allow the apps below to control your computer.")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
      row
    }
    .padding(Scene.settingsRowInset)
    .frame(width: Scene.settingsCard.width, height: Scene.settingsCard.height)
    .background(.background, in: shape)
    .overlay { shape.strokeBorder(.separator, lineWidth: Metrics.Size.hairlineStroke) }
    .scaleEffect(Self.enteringScale.mixed(with: 1, by: visibility))
    .opacity(visibility)
    .position(x: Scene.settingsCard.midX, y: Scene.settingsCard.midY)
  }

  private var row: some View {
    HStack(spacing: Metrics.Spacing.regular) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: Self.iconSide, height: Self.iconSide)
      Text("Macousel")
        .font(.subheadline)
      Spacer(minLength: 0)
      Toggle("Macousel", isOn: .constant(toggle > 0.5))
        .toggleStyle(.switch)
        .controlSize(.mini)
        .labelsHidden()
        .animation(.default, value: toggle > 0.5)
        .allowsHitTesting(false)
    }
    .frame(height: Scene.settingsRowHeight)
  }
}
