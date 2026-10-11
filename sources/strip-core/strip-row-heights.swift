import Foundation

public enum VerticalNeighbor: Sendable, CaseIterable {
  case above, below
}

extension Column {
  mutating func setHeightShare(
    _ share: Double, ofRow row: Int, borrowingFromRow neighbor: Int
  ) -> Bool {
    guard display == .stacked, row != neighbor, windows.indices.contains(row),
      windows.indices.contains(neighbor)
    else { return false }
    let total = Double(windows.count)
    let pairShare = (heightWeights[row] + heightWeights[neighbor]) / total
    let floor = Column.minimumHeightShare
    guard pairShare >= 2 * floor else { return false }
    let clamped = min(max(share, floor), pairShare - floor)
    guard abs(clamped - heightWeights[row] / total) > 1e-9 else { return false }
    heightWeights[row] = clamped * total
    heightWeights[neighbor] = (pairShare - clamped) * total
    return true
  }

  mutating func setHeightWeights(_ weights: [Double]) -> Bool {
    guard weights.count == windows.count, weights.allSatisfy({ $0 > 0 }) else { return false }
    heightWeights = weights
    normalizeWeights()
    return true
  }
}

extension Strip {
  @discardableResult
  public mutating func setHeight(
    _ points: Double, of window: WindowID, borrowingFrom neighbor: VerticalNeighbor,
    viewportHeight: Double, config: LayoutConfig
  ) -> Bool {
    guard let (columnIndex, row) = location(of: window) else { return false }
    let rowCount = columns[columnIndex].windows.count
    let rowsHeight =
      viewportHeight - 2 * config.outerGap - Double(rowCount - 1) * config.innerGap
    guard rowsHeight > 0 else { return false }
    return columns[columnIndex].setHeightShare(
      points / rowsHeight, ofRow: row,
      borrowingFromRow: neighbor == .above ? row - 1 : row + 1)
  }

  @discardableResult
  public mutating func setHeightWeights(
    _ weights: [Double], ofColumnContaining window: WindowID
  ) -> Bool {
    guard let (columnIndex, _) = location(of: window) else { return false }
    return columns[columnIndex].setHeightWeights(weights)
  }
}
