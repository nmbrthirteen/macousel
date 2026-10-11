import SwiftUI

struct LooseCardsView: View {
  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        ForEach(Array(PreviewMetrics.Cards.looseOff.enumerated()), id: \.offset) { _, unit in
          FloatingCardView(
            rect: CGRect(
              x: unit.minX * proxy.size.width, y: unit.minY * proxy.size.height,
              width: unit.width * proxy.size.width, height: unit.height * proxy.size.height))
        }
      }
    }
    .opacity(PreviewMetrics.Displays.offOpacity)
  }
}
