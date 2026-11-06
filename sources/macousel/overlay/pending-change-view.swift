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
      shape.fill(fill)
    case .glass:
      Color.clear.overlaySurface(in: shape, tint: fill)
    }
  }

  private var fill: Color {
    Color.accentColor.opacity(Metrics.Opacity.pendingFill)
  }
}
