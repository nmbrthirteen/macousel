import SwiftUI

struct StripIllustration: View {
  private struct Column {
    let start: Double
    let width: Double
  }

  private static let columns = [
    Column(start: 0.04, width: 0.2),
    Column(start: 0.26, width: 0.28),
    Column(start: 0.56, width: 0.2),
    Column(start: 0.78, width: 0.24),
  ]
  private static let focusedIndex = 1
  private static let screenStart = 0.02
  private static let screenEnd = 0.66
  private static let columnTop = 0.14
  private static let columnBottom = 0.86

  var body: some View {
    Canvas { context, size in
      for (index, column) in Self.columns.enumerated() {
        let rect = CGRect(
          x: column.start * size.width, y: Self.columnTop * size.height,
          width: column.width * size.width,
          height: (Self.columnBottom - Self.columnTop) * size.height)
        context.fill(
          Path(roundedRect: rect, cornerRadius: Metrics.Radius.illustrationColumn),
          with: .color(index == Self.focusedIndex ? .accentColor : .secondary.opacity(0.35)))
      }
      let screen = CGRect(
        x: Self.screenStart * size.width, y: 0,
        width: (Self.screenEnd - Self.screenStart) * size.width, height: size.height)
      context.stroke(
        Path(roundedRect: screen, cornerRadius: Metrics.Radius.panel),
        with: .color(.primary.opacity(0.6)), lineWidth: Metrics.Size.illustrationStroke)
    }
    .frame(height: Metrics.Size.illustrationHeight)
    .accessibilityHidden(true)
  }
}
