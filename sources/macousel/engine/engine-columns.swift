import CoreGraphics
import StripCore

nonisolated struct EngineColumns: Equatable, Sendable {
  struct Position: Equatable, Sendable {
    var column: Int
    var row: Int
  }

  struct Column: Equatable, Sendable {
    var windows: [EngineWindow]

    var windowIDs: [WindowID] { windows.compactMap { EngineWindowID.make($0.windowId) } }

    var width: Double? {
      guard let width = windows.first?.frame?.width, width > 0 else { return nil }
      return Double(width)
    }

    var horizontalExtent: ClosedRange<CGFloat>? {
      let frames = windows.compactMap(\.frame?.rect)
      guard let left = frames.map(\.minX).min(), let right = frames.map(\.maxX).max() else {
        return nil
      }
      return left...right
    }

    func isOnScreen(in viewport: CGRect) -> Bool {
      guard let extent = horizontalExtent else { return false }
      let overlap = min(extent.upperBound, viewport.maxX) - max(extent.lowerBound, viewport.minX)
      return overlap >= EngineColumns.minimumOverlap
    }

    var heightShares: [Double] {
      let heights = windows.map { Double($0.frame?.height ?? 0) }
      let total = heights.reduce(0, +)
      guard windows.count > 1, total > 0, !heights.contains(0) else {
        return windows.map { _ in 1 / Double(windows.count) }
      }
      return heights.map { $0 / total }
    }
  }

  static let minimumOverlap: CGFloat = 48
  static let alignmentTolerance = 1
  static let stackTolerance = 24

  let columns: [Column]

  init(_ windows: [EngineWindow]) {
    var grouped: [Column] = []
    for window in windows {
      if let previous = grouped.last?.windows.last, Self.stack(window, below: previous) {
        grouped[grouped.count - 1].windows.append(window)
      } else {
        grouped.append(Column(windows: [window]))
      }
    }
    columns = grouped
  }

  var windowIDs: [[WindowID]] { columns.map(\.windowIDs) }

  func position(of window: WindowID) -> Position? {
    position { EngineWindowID.make($0.windowId) == window }
  }

  func position(ofRawID identifier: Int32) -> Position? {
    position { $0.windowId == identifier }
  }

  func frame(of window: WindowID) -> CGRect? {
    columns.flatMap(\.windows).first { EngineWindowID.make($0.windowId) == window }?.frame?.rect
  }

  func columnIndex(of window: WindowID) -> Int? {
    position(of: window)?.column
  }

  func row(of window: WindowID) -> Int? {
    position(of: window)?.row
  }

  private func position(where matches: (EngineWindow) -> Bool) -> Position? {
    for (column, members) in columns.enumerated() {
      if let row = members.windows.firstIndex(where: matches) {
        return Position(column: column, row: row)
      }
    }
    return nil
  }

  private static func stack(_ window: EngineWindow, below previous: EngineWindow) -> Bool {
    guard let frame = window.frame, let above = previous.frame else { return false }
    return abs(frame.x - above.x) <= alignmentTolerance
      && frame.y >= above.y + above.height - stackTolerance
  }
}
