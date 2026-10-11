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
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        ForEach(Self.columns.indices, id: \.self) { index in
          columnShape(Self.columns[index], isFocused: index == Self.focusedIndex, in: proxy.size)
        }
        RoundedRectangle(cornerRadius: Metrics.Radius.panel)
          .stroke(Color.primary.opacity(0.6), lineWidth: Metrics.Size.illustrationStroke)
          .frame(
            width: (Self.screenEnd - Self.screenStart) * proxy.size.width, height: proxy.size.height
          )
          .offset(x: Self.screenStart * proxy.size.width)
      }
    }
    .frame(height: Metrics.Size.illustrationHeight)
    .accessibilityHidden(true)
  }

  private func columnShape(_ column: Column, isFocused: Bool, in size: CGSize) -> some View {
    RoundedRectangle(cornerRadius: Metrics.Radius.illustrationColumn)
      .fill(isFocused ? Color.accentColor : Color.secondary.opacity(0.35))
      .frame(
        width: column.width * size.width, height: (Self.columnBottom - Self.columnTop) * size.height
      )
      .offset(x: column.start * size.width, y: Self.columnTop * size.height)
  }
}
