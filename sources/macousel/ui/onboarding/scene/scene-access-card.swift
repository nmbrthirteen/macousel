import AppKit
import SwiftUI

struct SceneAccessCard: View {
  private typealias Scene = OnboardingSceneMetrics
  private static let radius = 12.0
  private static let iconSide = 18.0
  private static let titleSize = 12.0
  private static let detailSize = 9.5
  private static let rowSize = 11.0
  private static let knobInset = 2.0
  private static let enteringScale = 0.96

  let visibility: Double
  let toggle: Double

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
      Text("Accessibility")
        .font(.system(size: Self.titleSize, weight: .semibold))
      Text("Allow the apps below to control your computer.")
        .font(.system(size: Self.detailSize))
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
      row
    }
    .padding(Scene.settingsRowInset)
    .frame(width: Scene.settingsCard.width, height: Scene.settingsCard.height)
    .background(.background, in: RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
    .shadow(color: .black.opacity(0.3), radius: 16, y: 6)
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
        .font(.system(size: Self.rowSize))
      Spacer(minLength: 0)
      toggleSwitch
    }
    .frame(height: Scene.settingsRowHeight)
  }

  private var toggleSwitch: some View {
    Capsule()
      .fill(Color.primary.opacity(0.15))
      .overlay { Capsule().fill(Color.accentColor).opacity(toggle) }
      .overlay(alignment: .leading) {
        Circle()
          .fill(.white)
          .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
          .padding(Self.knobInset)
          .offset(x: (Scene.toggleSize.width - Scene.toggleSize.height) * toggle)
      }
      .frame(width: Scene.toggleSize.width, height: Scene.toggleSize.height)
  }
}
