public struct ColumnCursor: Sendable, Equatable {
  public static let places = 1...9

  public private(set) var columns: [[WindowID]]
  public private(set) var column = 0
  public private(set) var row = 0

  public init(columns: [[WindowID]], selecting window: WindowID? = nil) {
    self.columns = columns.filter { !$0.isEmpty }
    if let window, let position = position(of: window) {
      (column, row) = position
    }
  }

  public var window: WindowID? {
    columns.indices.contains(column) ? columns[column][row] : nil
  }

  @discardableResult
  public mutating func move(_ direction: Direction) -> Bool {
    switch direction {
    case .left: return select(column: column - 1)
    case .right: return select(column: column + 1)
    case .up: return select(row: row - 1)
    case .down: return select(row: row + 1)
    }
  }

  @discardableResult
  public mutating func jump(toPlace place: Int) -> Bool {
    guard Self.places.contains(place) else { return false }
    return select(column: place == Self.places.upperBound ? columns.count - 1 : place - 1)
  }

  private mutating func select(column target: Int) -> Bool {
    guard columns.indices.contains(target), target != column else { return false }
    column = target
    row = min(row, columns[target].count - 1)
    return true
  }

  private mutating func select(row target: Int) -> Bool {
    guard columns.indices.contains(column), columns[column].indices.contains(target) else {
      return false
    }
    row = target
    return true
  }

  private func position(of window: WindowID) -> (column: Int, row: Int)? {
    for (column, windows) in columns.enumerated() {
      if let row = windows.firstIndex(of: window) { return (column, row) }
    }
    return nil
  }
}
