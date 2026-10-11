import SwiftUI

struct MinimapView: View {
  let model: MinimapModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private var appearance: Animation {
    .easeOut(duration: OverlayTiming.minimapAppear)
  }

  private var disappearance: Animation {
    .easeOut(duration: OverlayTiming.slowFade)
  }

  private var transition: AnyTransition {
    reduceMotion
      ? .opacity : .opacity.combined(with: .scale(scale: Metrics.Minimap.hiddenScale))
  }

  var body: some View {
    ZStack {
      if model.isShown {
        container.transition(transition)
      }
    }
    .animation(model.isShown ? appearance : disappearance, value: model.isShown)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .accessibilityHidden(true)
  }

  private var container: some View {
    let geometry = MinimapGeometry(snapshot: model.snapshot)
    return ZStack(alignment: .topLeading) {
      lens(geometry.lens, radius: geometry.lensRadius)
      ForEach(geometry.cells) { cell in
        MinimapCellView(cell: cell, icons: model.icons)
      }
    }
    .frame(width: geometry.containerWidth, height: Metrics.Minimap.height, alignment: .topLeading)
    .background {
      if reduceTransparency {
        RoundedRectangle(cornerRadius: Metrics.Minimap.containerRadius, style: .continuous)
          .fill(Color(nsColor: .windowBackgroundColor))
      }
    }
    .animation(model.updateAnimation, value: model.snapshot)
  }

  private func lens(_ rect: CGRect, radius: Double) -> some View {
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    return shape
      .fill(Color.primary.opacity(Metrics.Opacity.minimapLens))
      .overlay(
        shape.strokeBorder(
          Color.primary.opacity(Metrics.Opacity.minimapLensBorder),
          lineWidth: Metrics.Size.hairlineStroke)
      )
      .frame(width: rect.width, height: rect.height)
      .offset(x: rect.minX, y: rect.minY)
  }
}
