import SwiftUI

struct OverviewPlaceholderView: View {
  let rect: CGRect

  var body: some View {
    PendingChangeView(radius: OverlayRadius.card)
      .frame(width: rect.width, height: rect.height)
      .offset(x: rect.minX, y: rect.minY)
      .allowsHitTesting(false)
  }
}
