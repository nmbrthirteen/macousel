import SwiftUI

struct OverviewPlaceholderView: View {
  let rect: CGRect
  let radius: Double

  var body: some View {
    PendingChangeView(radius: radius)
      .frame(width: rect.width, height: rect.height)
      .offset(x: rect.minX, y: rect.minY)
      .allowsHitTesting(false)
  }
}
