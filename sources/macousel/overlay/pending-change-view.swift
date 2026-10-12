import SwiftUI

struct PendingChangeView: View {
  enum Surface {
    case tint, glass
  }

  let radius: Double
  var surface = Surface.tint

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    switch surface {
    case .tint:
      shape.fill(fill).overlay { border(in: shape) }
    case .glass:
      Color.clear.overlaySurface(in: shape, tint: fill).overlay { border(in: shape) }
    }
  }

  private var fill: Color {
    Color.accentColor.opacity(Metrics.Opacity.pendingFill)
  }

  private func border(in shape: RoundedRectangle) -> some View {
    shape.strokeBorder(
      Color.accentColor.opacity(Metrics.Opacity.pendingBorder),
      lineWidth: Metrics.Overlay.pendingBorderWidth)
  }
}
