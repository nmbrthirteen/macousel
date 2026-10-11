import SwiftUI

struct MinimapCellView: View {
  let cell: MinimapCell
  let icons: MinimapIconCache

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Metrics.Minimap.cellRadius, style: .continuous)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      shape.fill(
        cell.isFocused ? Color.accentColor : Color.primary.opacity(Metrics.Opacity.minimapColumn))
      content.position(relative(cell.contentCenter))
      ForEach(Array(cell.tabDots.enumerated()), id: \.offset) { _, dot in
        Circle()
          .fill(tabDotColor)
          .frame(width: dot.width, height: dot.height)
          .position(relative(CGPoint(x: dot.midX, y: dot.midY)))
      }
    }
    .frame(width: cell.rect.width, height: cell.rect.height)
    .offset(x: cell.rect.minX, y: cell.rect.minY)
  }

  private var tabDotColor: Color {
    cell.isFocused ? .white : Color.primary.opacity(Metrics.Opacity.minimapTabDot)
  }

  @ViewBuilder
  private var content: some View {
    switch cell.content {
    case .icon(let bundleIdentifier):
      Image(nsImage: icons.icon(for: bundleIdentifier))
        .resizable()
        .interpolation(.high)
        .frame(width: Metrics.Minimap.iconSide, height: Metrics.Minimap.iconSide)
    case .number(let number):
      Text("\(number)")
        .font(
          .system(size: Metrics.Minimap.numberFontSize, weight: .semibold, design: .rounded)
            .monospacedDigit()
        )
        .foregroundStyle(cell.isFocused ? Color.white : Color.primary.opacity(Metrics.Opacity.minimapCaption))
    case .none:
      EmptyView()
    }
  }

  private func relative(_ point: CGPoint) -> CGPoint {
    CGPoint(x: point.x - cell.rect.minX, y: point.y - cell.rect.minY)
  }
}
