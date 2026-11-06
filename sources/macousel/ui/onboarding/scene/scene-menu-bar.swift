import SwiftUI

struct SceneMenuBar: View {
  private typealias Scene = OnboardingSceneMetrics
  private static let statusSymbols = ["wifi", "battery.100percent", "magnifyingglass", "switch.2"]
  private static let clock = "Tue 9:41"
  private static let highlightInset = 3.0
  private static let highlightRadius = 5.0

  let position: StripPosition?
  var highlight = 0.0

  var body: some View {
    HStack(spacing: Scene.menuBarSpacing) {
      Spacer(minLength: 0)
      appItem
        .frame(width: Scene.appItemWidth, height: Scene.menuBarHeight)
        .background {
          RoundedRectangle(cornerRadius: Self.highlightRadius, style: .continuous)
            .fill(.tertiary)
            .opacity(highlight)
            .padding(.vertical, Self.highlightInset)
        }
      ForEach(Self.statusSymbols, id: \.self) {
        Image(systemName: $0).frame(width: Scene.statusItemWidth)
      }
      Text(Self.clock).frame(width: Scene.clockWidth, alignment: .trailing)
    }
    .font(.subheadline.weight(.medium))
    .foregroundStyle(.white)
    .padding(.trailing, Scene.menuBarInset)
    .frame(height: Scene.menuBarHeight)
  }

  @ViewBuilder
  private var appItem: some View {
    if let position, let geometry = MenuBarPagesGeometry(position: position) {
      Image(nsImage: MenuBarPagesImage.cached(geometry))
        .renderingMode(.template)
    } else {
      Image(systemName: "rectangle.split.3x1")
    }
  }
}
