import SwiftUI

struct StripPreviewLayer: View {
  let geometry: StripPreviewGeometry
  let decoration: StripPreviewDecoration

  private var borderWidth: Double? {
    decoration.focusBorderWidth.map { geometry.borderLineWidth(for: $0) }
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      if let card = decoration.floatingCard, !card.isAboveTiled {
        FloatingCardView(rect: geometry.cardRect(card))
      }
      ForEach(geometry.windows) { window in
        PreviewWindowView(window: window, decoration: decoration, borderWidth: borderWidth)
          .transition(.identity)
      }
      if let card = decoration.floatingCard, card.isAboveTiled {
        FloatingCardView(rect: geometry.cardRect(card))
      }
    }
    .frame(
      width: geometry.container.width, height: geometry.container.height, alignment: .topLeading)
  }
}
