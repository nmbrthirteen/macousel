import SwiftUI

struct PendingChangeView: View {
  let radius: Double

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    shape
      .fill(Color.accentColor.opacity(Metrics.Opacity.pendingFill))
      .overlay {
        shape.strokeBorder(
          Color.accentColor.opacity(Metrics.Opacity.pendingBorder),
          lineWidth: Metrics.Overlay.pendingBorderWidth)
      }
  }
}
