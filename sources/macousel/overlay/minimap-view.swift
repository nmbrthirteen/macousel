import SwiftUI

struct MinimapView: View {
  let model: MinimapModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.colorSchemeContrast) private var contrast

  private var appearance: Animation {
    .easeOut(duration: OverlayTiming.minimapAppear)
  }

  private var disappearance: Animation {
    .easeOut(duration: OverlayTiming.minimapDisappear)
  }

  private var transition: AnyTransition {
    reduceMotion
      ? .opacity : .opacity.combined(with: .scale(scale: OverlayTiming.minimapHiddenScale))
  }

  private var focusAnimation: Animation? {
    reduceMotion
      ? nil
      : .spring(
        response: OverlayTiming.minimapFocusResponse,
        dampingFraction: OverlayTiming.criticalDamping)
  }

  private var containerShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: OverlayRadius.minimapContainer, style: .continuous)
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
    return VStack(spacing: 0) {
      strip(geometry)
      MinimapLabelView(model: model)
        .frame(height: Metrics.Minimap.labelLineHeight)
        .padding(.horizontal, Metrics.Minimap.horizontalPadding)
    }
    .frame(
      width: geometry.containerWidth, height: Metrics.Minimap.panelHeight, alignment: .top)
    .background {
      if reduceTransparency {
        containerShape.fill(Color(nsColor: .windowBackgroundColor))
      }
    }
    .overlay {
      if contrast == .increased {
        containerShape.strokeBorder(.primary, lineWidth: Metrics.Size.contrastStroke)
      }
    }
    .contentShape(Rectangle())
    .gesture(pointerGesture, isEnabled: model.isInteractive)
  }

  private func strip(_ geometry: MinimapGeometry) -> some View {
    ZStack(alignment: .topLeading) {
      lens(geometry.lens, radius: geometry.lensRadius)
      ForEach(geometry.cells) { cell in
        MinimapCellView(
          cell: cell, icons: model.icons, isPlaceholder: model.lift?.cell == cell.id)
      }
      if let ring = geometry.focusRing, model.lift?.cell != ring.cell {
        focusRing(ring)
      }
      if let lift = model.lift, let cell = liftedCell(lift) {
        MinimapCellView(cell: cell, icons: model.icons, isLifted: true, liftOffset: lift.offset)
      }
    }
    .frame(width: geometry.containerWidth, height: Metrics.Minimap.height, alignment: .topLeading)
  }

  // The ring is one view that moves between tiles, so focus changes read as motion.
  // Its animation keys on the focused window, so scrolling alone never makes it trail.
  private func focusRing(_ ring: MinimapGeometry.FocusRing) -> some View {
    RoundedRectangle(cornerRadius: ring.cornerRadius, style: .continuous)
      .strokeBorder(
        Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: Metrics.Minimap.focusRingWidth)
      .frame(width: ring.rect.width, height: ring.rect.height)
      .offset(x: ring.rect.minX, y: ring.rect.minY)
      .animation(focusAnimation, value: ring.cell)
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
      .fill(.quaternary)
      .overlay(
        shape.strokeBorder(Color(nsColor: .separatorColor), lineWidth: Metrics.Size.hairlineStroke)
      )
      .frame(width: rect.width, height: rect.height)
      .offset(x: rect.minX, y: rect.minY)
  }
}
