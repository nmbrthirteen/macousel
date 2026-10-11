import CoreGraphics

nonisolated struct MenuBarPillGeometry: Equatable {
  struct Pill: Equatable {
    let isFocused: Bool
    let segments: [CGRect]
  }

  static let maximumColumns = 12
  static let pillWidth = 3.0
  static let pillGap = 2.0
  static let imageHeight = 16.0
  static let restingPillHeight = 10.0
  static let focusedPillHeight = 14.0
  static let segmentGap = 1.0
  static let stackedSegmentLimit = 3

  let size: CGSize
  let pills: [Pill]

  init?(position: StripPosition) {
    guard (1...Self.maximumColumns).contains(position.columnCount),
      (0..<position.columnCount).contains(position.focusedIndex)
    else { return nil }
    let count = position.columnCount
    size = CGSize(
      width: Double(count) * Self.pillWidth + Double(count - 1) * Self.pillGap,
      height: Self.imageHeight)
    pills = (0..<count).map { index in
      let isFocused = index == position.focusedIndex
      return Pill(
        isFocused: isFocused,
        segments: Self.segments(
          at: Double(index) * (Self.pillWidth + Self.pillGap),
          stackedWindows: isFocused ? position.windowsInFocusedColumn : 1,
          height: isFocused ? Self.focusedPillHeight : Self.restingPillHeight))
    }
  }

  private static func segments(at x: Double, stackedWindows: Int, height: Double) -> [CGRect] {
    let count = min(max(stackedWindows, 1), stackedSegmentLimit)
    let top = (imageHeight - height) / 2
    let segmentHeight = (height - Double(count - 1) * segmentGap) / Double(count)
    return (0..<count).map {
      CGRect(
        x: x, y: top + Double($0) * (segmentHeight + segmentGap), width: pillWidth,
        height: segmentHeight)
    }
  }
}
