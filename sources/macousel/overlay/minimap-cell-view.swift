import SwiftUI

struct MinimapCellView: View {
  let cell: MinimapCell
  let icons: AppIconCache
  var isPlaceholder = false
  var isLifted = false
  var liftOffset = 0.0

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: cell.cornerRadius, style: .continuous)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      if isPlaceholder {
        PendingChangeView(radius: cell.cornerRadius)
      } else {
        shape.fill(Color.primary.opacity(Metrics.Opacity.minimapColumn))
        content
        ForEach(Array(cell.tabDots.enumerated()), id: \.offset) { _, dot in
          Circle()
            .fill(Color.primary.opacity(Metrics.Opacity.minimapTabDot))
            .frame(width: dot.width, height: dot.height)
            .position(relative(CGPoint(x: dot.midX, y: dot.midY)))
        }
      }
    }
    .frame(width: cell.rect.width, height: cell.rect.height)
    .opacity(cell.isOnScreen || isLifted ? 1 : Metrics.Opacity.minimapOffscreen)
    .overlayLift(
      isLifted, scale: OverlayTiming.minimapLiftScale,
      shadowRadius: Metrics.Minimap.liftShadowRadius)
    .offset(x: cell.rect.minX + liftOffset, y: cell.rect.minY)
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
        .font(.overlay(.small, weight: .semibold))
        .foregroundStyle(Color.primary.opacity(Metrics.Opacity.minimapNumber))
        .position(relative(number.center))
    }
  }

  private func relative(_ point: CGPoint) -> CGPoint {
    CGPoint(x: point.x - cell.rect.minX, y: point.y - cell.rect.minY)
  }
}
