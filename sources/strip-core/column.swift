import Foundation

public struct Column: Sendable, Codable, Equatable {
  public internal(set) var windows: [WindowID]
  public var width: ColumnWidth
  public var display: ColumnDisplay
  public internal(set) var activeRow: Int
  public internal(set) var heightWeights: [Double]
  public var isFullWidth: Bool

  public var activeWindow: WindowID { windows[activeRow] }

  static let minimumHeightShare = 0.1

  init(window: WindowID, width: ColumnWidth, isFullWidth: Bool = false) {
    windows = [window]
    self.width = width
    display = .stacked
    activeRow = 0
    heightWeights = [1.0]
    self.isFullWidth = isFullWidth
  }

  func pixelWidth(usableWidth: Double, innerGap: Double) -> Double {
    if isFullWidth { return usableWidth.rounded() }
    switch width {
    case .fraction(let fraction):
      return (fraction * (usableWidth + innerGap) - innerGap).rounded()
    case .fixed(let points):
      return min(points, usableWidth).rounded()
    }
  }

  mutating func appendWindow(_ window: WindowID) {
    windows.append(window)
    heightWeights.append(1.0)
    activeRow = windows.count - 1
  }

  mutating func removeWindow(at row: Int) {
    precondition(windows.count > 1, "removeWindow would leave the column empty")
    windows.remove(at: row)
    heightWeights.remove(at: row)
    if row < activeRow || activeRow >= windows.count {
      activeRow -= 1
    }
    normalizeWeights()
    if windows.count == 1 { display = .stacked }
  }

  mutating func setActiveRow(_ row: Int) {
    precondition(windows.indices.contains(row), "row out of range")
    activeRow = row
  }

  mutating func moveActiveRow(to target: Int) {
    precondition(windows.indices.contains(target), "row out of range")
    windows.swapAt(activeRow, target)
    heightWeights.swapAt(activeRow, target)
    activeRow = target
  }

  mutating func equalizeHeights() {
    heightWeights = Array(repeating: 1.0, count: windows.count)
  }

  mutating func normalizeWeights() {
    let total = heightWeights.reduce(0, +)
    guard total > 0 else {
      equalizeHeights()
      return
    }
    let scale = Double(windows.count) / total
    heightWeights = heightWeights.map { $0 * scale }
  }

  mutating func adjustActiveHeight(by delta: Double) -> Bool {
    let count = windows.count
    guard count > 1, display == .stacked else { return false }
    let floor = Column.minimumHeightShare
    let total = Double(count)
    let shares = heightWeights.map { $0 / total }
    let old = shares[activeRow]
    let new = min(max(old + delta, floor), 1 - floor * Double(count - 1))
    guard abs(new - old) > 1e-9 else { return false }

    var result = shares
    result[activeRow] = new
    var free = windows.indices.filter { $0 != activeRow }
    var remaining = 1 - new
    while !free.isEmpty {
      let freeSum = free.reduce(0) { $0 + shares[$1] }
      let scale = remaining / freeSum
      let pinned = free.filter { shares[$0] * scale < floor }
      if pinned.isEmpty {
        for row in free { result[row] = shares[row] * scale }
        break
      }
      for row in pinned { result[row] = floor }
      remaining -= floor * Double(pinned.count)
      free.removeAll { pinned.contains($0) }
    }
    heightWeights = result.map { $0 * total }
    normalizeWeights()
    return true
  }
}
