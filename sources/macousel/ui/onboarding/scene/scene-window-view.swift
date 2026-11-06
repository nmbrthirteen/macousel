import SwiftUI

struct SceneWindowView: View {
  private typealias Scene = OnboardingSceneMetrics
  private static let lightSize = 6.0
  private static let lightSpacing = 4.0
  private static let lightInset = 8.0
  private static let lightColors: [Color] = [.red, .yellow, .green]

  let window: SceneWindow

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Scene.windowRadius, style: .continuous)
  }

  var body: some View {
    VStack(spacing: 0) {
      titleBar
      SceneWindowContent(style: window.style)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .clipShape(shape)
    .overlay { shape.strokeBorder(.separator, lineWidth: Metrics.Size.hairlineStroke) }
    .transformEnvironment(\.colorScheme) { if window.style == .console { $0 = .dark } }
    .frame(width: window.rect.width, height: window.rect.height)
    .position(x: window.rect.midX, y: window.rect.midY)
    .zIndex(window.isFocused ? 1 : 0)
  }

  private var titleBar: some View {
    HStack(spacing: Self.lightSpacing) {
      ForEach(Self.lightColors.indices, id: \.self) { index in
        Circle()
          .fill(window.isFocused ? AnyShapeStyle(Self.lightColors[index]) : AnyShapeStyle(.quaternary))
          .frame(width: Self.lightSize, height: Self.lightSize)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, Self.lightInset)
    .frame(height: Scene.titleBarHeight)
  }
}
