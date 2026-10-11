import SwiftUI

struct OverviewView: View {
  let model: OverviewModel

  var body: some View {
    GeometryReader { proxy in
      let geometry = OverviewGeometry(snapshot: model.snapshot, size: proxy.size)
      ZStack(alignment: .topLeading) {
        backdrop
        ForEach(geometry.cards) { card in
          OverviewCardView(card: card, icon: model.icon(for: card.content.bundleIdentifier))
            .frame(width: card.rect.width, height: card.rect.height)
            .offset(x: card.rect.minX, y: card.rect.minY)
            .onTapGesture { model.onSelect(card.id) }
        }
      }
    }
  }

  private var backdrop: some View {
    Rectangle()
      .fill(Color.black.opacity(Metrics.Opacity.overviewBackdrop))
      .overlaySurface(in: Rectangle())
      .contentShape(Rectangle())
      .onTapGesture { model.onDismiss() }
      .accessibilityLabel("Close overview")
      .accessibilityAddTraits(.isButton)
  }
}
