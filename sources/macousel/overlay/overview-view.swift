import SwiftUI

struct OverviewView: View {
  let model: OverviewModel
  @State private var isPressing = false

  var body: some View {
    GeometryReader { proxy in
      let geometry = OverviewGeometry(snapshot: model.arrangement, size: proxy.size)
      ZStack(alignment: .topLeading) {
        backdrop
        if let lift = model.lift, let slot = geometry.cards.first(where: { $0.id == lift.window }) {
          OverviewPlaceholderView(rect: slot.rect)
        }
        ZStack(alignment: .topLeading) {
          ForEach(geometry.cards) { card in
            cardView(card)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassContainer(spacing: 0)
        if model.lift == nil {
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
  }

  private func cardView(_ card: OverviewGeometry.Card) -> some View {
    let isLifted = model.lift?.window == card.id
    let rect = isLifted ? model.lift?.rect ?? card.rect : card.rect
    return OverviewCardView(
      card: card, icon: model.icon(for: card.content.bundleIdentifier), isLifted: isLifted
    )
    .frame(width: rect.width, height: rect.height)
    .offset(x: rect.minX, y: rect.minY)
    .zIndex(isLifted ? 1 : 0)
    .accessibilityAction { model.onSelect(card.id) }
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
        if !isPressing {
          isPressing = true
          model.pressed(at: value.startLocation, in: size)
        }
        model.dragged(to: value.location, in: size)
      }
      .onEnded { value in
        isPressing = false
        model.released(at: value.location, in: size)
      }
  }

  private var backdrop: some View {
    Rectangle()
      .fill(Color.black.opacity(Metrics.Opacity.overviewBackdrop))
      .background(.ultraThinMaterial)
      .accessibilityLabel("Close overview")
      .accessibilityAddTraits(.isButton)
      .accessibilityAction { model.onDismiss() }
  }
}
