import SwiftUI

struct SceneMenu: View {
  private typealias Scene = OnboardingSceneMetrics
  private static let fontSize = 12.0
  private static let radius = 8.0
  private static let rowRadius = 4.0
  private static let rowInset = 10.0
  private static let enteringScale = 0.97

  let visibility: Double
  let highlighted: Int?

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Scene.menuItems.indices, id: \.self) { index in
        Text(Scene.menuItems[index])
          .font(.system(size: Self.fontSize))
          .foregroundStyle(index == highlighted ? Color.white : Color.primary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, Self.rowInset)
          .frame(height: Scene.menuRowHeight)
          .background(
            index == highlighted ? Color.accentColor : .clear,
            in: RoundedRectangle(cornerRadius: Self.rowRadius, style: .continuous))
      }
    }
    .padding(Scene.menuPadding)
    .frame(width: Scene.menuFrame.width, height: Scene.menuFrame.height)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    .scaleEffect(Self.enteringScale.mixed(with: 1, by: visibility), anchor: .top)
    .opacity(visibility)
    .position(x: Scene.menuFrame.midX, y: Scene.menuFrame.midY)
  }
}
