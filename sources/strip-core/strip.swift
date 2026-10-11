import Foundation

public struct Strip: Sendable, Codable, Equatable {
  public internal(set) var columns: [Column] = []
  public internal(set) var focusedColumn: Int?
  public var scrollOffset: Double = 0

  public init() {}

  public var isEmpty: Bool { columns.isEmpty }

  public var focusedWindow: WindowID? {
    focusedColumn.map { columns[$0].activeWindow }
  }

  public var windows: [WindowID] { columns.flatMap(\.windows) }

  public func contains(_ window: WindowID) -> Bool {
    location(of: window) != nil
  }

  public func columnIndex(of window: WindowID) -> Int? {
    location(of: window)?.column
  }

  func location(of window: WindowID) -> (column: Int, row: Int)? {
    for (index, column) in columns.enumerated() {
      if let row = column.windows.firstIndex(of: window) {
        return (index, row)
      }
    }
    return nil
  }

  public mutating func insert(
    _ window: WindowID, width: ColumnWidth? = nil, config: LayoutConfig
  ) {
    guard !contains(window) else { return }
    let index = (focusedColumn ?? -1) + 1
    let column = Column(window: window, width: width ?? .fraction(config.defaultWidth))
    columns.insert(column, at: index)
    focusedColumn = index
  }

  public mutating func append(_ window: WindowID, width: ColumnWidth) {
    guard !contains(window) else { return }
    columns.append(Column(window: window, width: width))
    if focusedColumn == nil { focusedColumn = 0 }
  }

  @discardableResult
  public mutating func remove(_ window: WindowID) -> Bool {
    guard let (columnIndex, row) = location(of: window) else { return false }
    guard columns[columnIndex].windows.count == 1 else {
      columns[columnIndex].removeWindow(at: row)
      return true
    }
    columns.remove(at: columnIndex)
    guard let focused = focusedColumn else { return true }
    if columns.isEmpty {
      focusedColumn = nil
    } else if columnIndex < focused {
      focusedColumn = focused - 1
    } else if columnIndex == focused {
      focusedColumn = min(focused, columns.count - 1)
    }
    return true
  }

  @discardableResult
  public mutating func focus(_ window: WindowID) -> Bool {
    guard let (columnIndex, row) = location(of: window) else { return false }
    let changed = focusedColumn != columnIndex || columns[columnIndex].activeRow != row
    focusedColumn = columnIndex
    columns[columnIndex].setActiveRow(row)
    return changed
  }

  @discardableResult
  public mutating func focus(_ direction: Direction) -> Bool {
    guard let focused = focusedColumn else { return false }
    switch direction {
    case .left, .right:
      let target = direction == .left ? focused - 1 : focused + 1
      guard columns.indices.contains(target) else { return false }
      focusedColumn = target
    case .up, .down:
      let row = columns[focused].activeRow
      let target = direction == .up ? row - 1 : row + 1
      guard columns[focused].windows.indices.contains(target) else { return false }
      columns[focused].setActiveRow(target)
    }
    return true
  }

  @discardableResult
  public mutating func focusFirst() -> Bool {
    guard !isEmpty, focusedColumn != 0 else { return false }
    focusedColumn = 0
    return true
  }

  @discardableResult
  public mutating func focusLast() -> Bool {
    guard !isEmpty, focusedColumn != columns.count - 1 else { return false }
    focusedColumn = columns.count - 1
    return true
  }
}
