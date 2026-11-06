import SwiftUI

struct OverviewView: View {
  let model: OverviewModel

  var body: some View {
    ZStack(alignment: .bottom) {
      strip
      if model.previews.needsPermission {
        OverviewPermissionNotice {
          model.previews.requestPermission()
          model.onDismiss()
        }
        .opacity(model.isExpanded ? 1 : 0)
      }
    }
  }

  private var strip: some View {
    GeometryReader { proxy in
      let geometry = OverviewGeometry(snapshot: model.arrangement, size: proxy.size)
      ZStack(alignment: .topLeading) {
        backdrop
        if let lift = model.lift, let slot = geometry.cards.first(where: { $0.id == lift.window }) {
          OverviewPlaceholderView(rect: slot.rect, radius: geometry.cornerRadius)
        }
        ZStack(alignment: .topLeading) {
          ForEach(geometry.cards) { card in
            cardView(card, radius: geometry.cornerRadius)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        if model.lift == nil, model.isExpanded {
          OverviewHandlesView(
            areas: geometry.hitAreas, activeColumnWindow: model.resizeLabel?.window,
            activeDivider: model.activeDivider)
        }
        label(in: geometry)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .contentShape(Rectangle())
      .gesture(pointerGesture(size: proxy.size))
    }
    .onDisappear {
      if case .idle = model.interaction { return }
      model.endInteraction()
    }
  }

  // The shadow sits outside the flight scale, so a card at its window frame casts a window's
  // shadow rather than a magnified card shadow.
  private func cardView(_ card: OverviewGeometry.Card, radius: Double) -> some View {
    let isLifted = model.lift?.window == card.id
    let isHovered = model.hovered == card.id && model.isExpanded && model.lift == nil
    let rect = isLifted ? model.lift?.rect ?? card.rect : card.rect
    let flight = model.isExpanded ? OverviewFlight.Transform.identity : collapsedFlight(of: card)
    return OverviewCardView(
      card: card, icon: model.icon(for: card.content.bundleIdentifier), previews: model.previews,
      radius: radius, isLifted: isLifted, isHovered: isHovered, showsChrome: model.isExpanded
    )
    .frame(width: rect.width, height: rect.height)
    .onHover { model.hover(card.id, isInside: $0) }
    .scaleEffect(flight.scale)
    .offset(flight.offset)
    .shadow(
      color: Color(nsColor: .shadowColor).opacity(
        model.isExpanded ? Metrics.Opacity.overviewCardShadow : Metrics.Opacity.windowShadow),
      radius: model.isExpanded ? Metrics.Overview.cardShadowRadius : Metrics.Overview.windowShadowRadius,
      y: model.isExpanded ? Metrics.Overview.cardShadowOffset : Metrics.Overview.windowShadowOffset)
    .opacity(model.isExpanded || (model.animates && card.content.frame != nil) ? 1 : 0)
    .offset(x: rect.minX, y: rect.minY)
    .zIndex(isLifted ? 2 : isHovered ? 1 : 0)
    .accessibilityAction { model.onSelect(card.id) }
  }

  private func collapsedFlight(of card: OverviewGeometry.Card) -> OverviewFlight.Transform {
    guard model.animates, let frame = card.content.frame else { return .identity }
    return OverviewFlight.transform(
      from: card.rect, to: OverviewFlight.source(of: frame, on: model.displayFrame))
  }

  @ViewBuilder
  private func label(in geometry: OverviewGeometry) -> some View {
    if let label = model.resizeLabel, let card = geometry.cards.first(where: { $0.id == label.window }) {
      OverviewResizeLabel(text: label.text, anchor: card.rect)
    }
  }

  private func pointerGesture(size: CGSize) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if case .idle = model.interaction { model.pressed(at: value.startLocation, in: size) }
        model.dragged(to: value.location, in: size)
      }
      .onEnded { model.released(at: $0.location, in: size) }
  }

  private var backdrop: some View {
    Color.clear
      .contentShape(Rectangle())
      .accessibilityLabel("Close overview")
      .accessibilityAddTraits(.isButton)
      .accessibilityAction { model.onDismiss() }
  }
}
