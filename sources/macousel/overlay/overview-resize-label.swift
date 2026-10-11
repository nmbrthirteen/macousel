import SwiftUI

struct OverviewResizeLabel: View {
  let text: String
  let anchor: CGRect

  var body: some View {
    Text(text)
      .font(.overlay(.large, weight: .semibold))
      .padding(.horizontal, Metrics.Spacing.comfortable)
      .frame(height: Metrics.Overview.labelHeight)
      .overlaySurface(in: Capsule())
      .frame(width: anchor.width)
      .offset(
        x: anchor.minX,
        y: anchor.minY - Metrics.Overview.labelHeight - Metrics.Overview.labelOffset)
      .allowsHitTesting(false)
  }
}
