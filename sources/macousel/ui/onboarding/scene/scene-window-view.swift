import SwiftUI

struct SceneWindowView: View {
  private typealias Scene = OnboardingSceneMetrics
  private static let lightSize = 6.0
  private static let lightSpacing = 4.0
  private static let lightInset = 8.0
  private static let lightColors: [Color] = [.red, .yellow, .green]
  private static let focusedShadow = 10.0
  private static let restingShadow = 4.0

  let window: SceneWindow

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Scene.windowRadius, style: .continuous)
  }

  private var isDark: Bool { window.style == .console }

  var body: some View {
    VStack(spacing: 0) {
      titleBar
      SceneWindowContent(style: window.style)
    }
    .background(isDark ? Color(white: 0.14) : Color(nsColor: .windowBackgroundColor))
    .clipShape(shape)
    .overlay { shape.strokeBorder(.black.opacity(0.12), lineWidth: Metrics.Size.hairlineStroke) }
    .shadow(
      color: .black.opacity(window.isFocused ? 0.3 : 0.15),
      radius: window.isFocused ? Self.focusedShadow : Self.restingShadow,
      y: window.isFocused ? 4 : 1)
    .frame(width: window.rect.width, height: window.rect.height)
    .position(x: window.rect.midX, y: window.rect.midY)
    .zIndex(window.isFocused ? 1 : 0)
  }

  private var titleBar: some View {
    HStack(spacing: Self.lightSpacing) {
      ForEach(Self.lightColors.indices, id: \.self) { index in
        Circle()
          .fill(window.isFocused ? Self.lightColors[index] : Color.gray.opacity(0.35))
          .frame(width: Self.lightSize, height: Self.lightSize)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, Self.lightInset)
    .frame(height: Scene.titleBarHeight)
  }
}
