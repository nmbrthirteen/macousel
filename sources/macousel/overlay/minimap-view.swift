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
      ? .opacity : .opacity.combined(with: .scale(scale: OverlayTiming.hiddenScale))
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
    let geometry = MinimapGeometry(snapshot: model.arrangement)
    return ZStack(alignment: .topLeading) {
      lens(geometry.lens, radius: geometry.lensRadius)
      ForEach(geometry.cells) { cell in
        MinimapCellView(
          cell: cell, icons: model.icons, isPlaceholder: model.lift?.cell == cell.id)
      }
      if let lift = model.lift, let cell = liftedCell(lift) {
        MinimapCellView(cell: cell, icons: model.icons, isLifted: true, liftOffset: lift.offset)
      }
    }
    .frame(width: geometry.containerWidth, height: Metrics.Minimap.height, alignment: .topLeading)
    .background {
      if reduceTransparency {
        RoundedRectangle(cornerRadius: OverlayRadius.minimapContainer, style: .continuous)
          .fill(Color(nsColor: .windowBackgroundColor))
      }
    }
    .contentShape(Rectangle())
    .gesture(pointerGesture, isEnabled: model.isInteractive)
  }

  private func liftedCell(_ lift: MinimapModel.Lift) -> MinimapCell? {
    MinimapGeometry(snapshot: model.snapshot).cells.first { $0.id == lift.cell }
  }

  private var pointerGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if case .idle = model.interaction { model.pressed(at: value.startLocation) }
        model.dragged(to: value.location)
      }
      .onEnded { model.released(at: $0.location) }
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
