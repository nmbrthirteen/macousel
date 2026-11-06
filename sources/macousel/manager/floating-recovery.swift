import CoreGraphics

nonisolated enum FloatingRecovery {
  static let shownShare = 0.5

  static func frame(for frame: CGRect, displays: [CGRect], into visibleFrame: CGRect) -> CGRect? {
    let area = frame.width * frame.height
    guard area > 0, !visibleFrame.isEmpty else { return nil }
    let shown = displays.reduce(0.0) { total, display in
      let shared = frame.intersection(display)
      return shared.isNull ? total : total + shared.width * shared.height
    }
    guard shown < area * shownShare else { return nil }
    return CGRect(
      origin: CGPoint(
        x: clamp(
          frame.minX, from: visibleFrame.minX, length: frame.width, within: visibleFrame.width),
        y: clamp(
          frame.minY, from: visibleFrame.minY, length: frame.height, within: visibleFrame.height)),
      size: frame.size)
  }

  // A window larger than the visible frame keeps its size and lines up with the top left.
  private static func clamp(
    _ value: CGFloat, from start: CGFloat, length: CGFloat, within available: CGFloat
  ) -> CGFloat {
    min(max(value, start), max(start + available - length, start))
  }
}
