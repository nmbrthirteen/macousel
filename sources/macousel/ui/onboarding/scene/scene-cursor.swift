import SwiftUI

struct SceneCursorView: View {
  private static let size = CGSize(width: 12, height: 19)
  private static let pressedScale = 0.85
  private static let outline = 1.2

  let point: CGPoint
  let press: Double

  var body: some View {
    ArrowShape()
      .fill(.black)
      .overlay { ArrowShape().stroke(.white, style: StrokeStyle(lineWidth: Self.outline, lineJoin: .round)) }
      .frame(width: Self.size.width, height: Self.size.height)
      .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
      .scaleEffect(1 - (1 - Self.pressedScale) * press, anchor: .topLeading)
      .position(x: point.x + Self.size.width / 2, y: point.y + Self.size.height / 2)
  }
}

private struct ArrowShape: Shape {
  private static let outline: [CGPoint] = [
    CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0.84), CGPoint(x: 0.3, y: 0.66),
    CGPoint(x: 0.56, y: 0.98), CGPoint(x: 0.75, y: 0.9), CGPoint(x: 0.52, y: 0.6),
    CGPoint(x: 0.96, y: 0.6),
  ]

  func path(in rect: CGRect) -> Path {
    Path { path in
      path.addLines(
        Self.outline.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
      path.closeSubpath()
    }
  }
}
