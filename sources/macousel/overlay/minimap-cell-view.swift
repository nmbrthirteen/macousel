import SwiftUI

struct MinimapCellView: View {
  let cell: MinimapCell
  let icons: MinimapIconCache

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: cell.cornerRadius, style: .continuous)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      shape.fill(
        cell.isFocused ? Color.accentColor : Color.primary.opacity(Metrics.Opacity.minimapColumn))
      content
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

  private var numberColor: Color {
    cell.isFocused ? .white : Color.primary.opacity(Metrics.Opacity.minimapNumber)
  }

  @ViewBuilder
  private var content: some View {
    if let icon = cell.content.icon {
      Image(nsImage: icons.icon(for: icon.bundleIdentifier))
        .resizable()
        .interpolation(.high)
        .frame(width: Metrics.Minimap.iconSide, height: Metrics.Minimap.iconSide)
        .position(relative(icon.center))
    }
    if let number = cell.content.number {
      Text("\(number.value)")
        .font(
          .system(size: Metrics.Minimap.numberFontSize, weight: .semibold, design: .rounded)
            .monospacedDigit()
        )
        .foregroundStyle(numberColor)
        .position(relative(number.center))
    }
  }

  private func relative(_ point: CGPoint) -> CGPoint {
    CGPoint(x: point.x - cell.rect.minX, y: point.y - cell.rect.minY)
  }
}
