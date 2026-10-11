import SwiftUI

struct MinimapView: View {
  let model: MinimapModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        capsule.transition(transition)
      }
    }
    .animation(model.isShown ? appearance : disappearance, value: model.isShown)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityHidden(true)
  }

  private var capsule: some View {
    let geometry = MinimapGeometry(snapshot: model.snapshot)
    return ZStack(alignment: .topLeading) {
      lens(geometry.lens)
      ForEach(geometry.cells) { cell in
        MinimapCellView(cell: cell, icons: model.icons)
      }
    }
    .frame(width: geometry.capsuleWidth, height: Metrics.Minimap.height, alignment: .topLeading)
    .overlaySurface(
      in: RoundedRectangle(cornerRadius: Metrics.Minimap.capsuleRadius, style: .continuous)
    )
    .animation(model.updateAnimation, value: model.snapshot)
  }

  private func lens(_ rect: CGRect) -> some View {
    let shape = RoundedRectangle(cornerRadius: Metrics.Minimap.lensRadius, style: .continuous)
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
