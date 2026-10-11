import Foundation

extension Strip {
  @discardableResult
  public mutating func moveFocused(_ direction: Direction) -> Bool {
    guard let focused = focusedColumn else { return false }
    switch direction {
    case .left, .right:
      let target = direction == .left ? focused - 1 : focused + 1
      guard columns.indices.contains(target) else { return false }
      columns.swapAt(focused, target)
      focusedColumn = target
    case .up, .down:
      let row = columns[focused].activeRow
      let target = direction == .up ? row - 1 : row + 1
      guard columns[focused].windows.indices.contains(target) else { return false }
      columns[focused].moveActiveRow(to: target)
    }
    return true
  }

  @discardableResult
  public mutating func move(_ window: WindowID, toColumn index: Int) -> Bool {
    guard let (columnIndex, _) = location(of: window) else { return false }
    let source = columns[columnIndex]
    remove(window)
    let target = min(max(index, 0), columns.count)
    columns.insert(
      Column(window: window, width: source.width, isFullWidth: source.isFullWidth), at: target)
    focusedColumn = target
    return true
  }

  @discardableResult
  public mutating func stackFocused(into direction: HorizontalDirection) -> Bool {
    guard let focused = focusedColumn else { return false }
    let neighbour = direction == .left ? focused - 1 : focused + 1
    guard columns.indices.contains(neighbour) else { return false }

    let window = columns[focused].activeWindow
    var target = neighbour
    if columns[focused].windows.count == 1 {
      columns.remove(at: focused)
      if neighbour > focused { target -= 1 }
    } else {
      columns[focused].removeWindow(at: columns[focused].activeRow)
    }
    columns[target].appendWindow(window)
    focusedColumn = target
    return true
  }

  @discardableResult
  public mutating func popOutFocused(to direction: HorizontalDirection) -> Bool {
    guard let focused = focusedColumn, columns[focused].windows.count > 1 else { return false }
    let source = columns[focused]
    columns[focused].removeWindow(at: source.activeRow)
    let target = direction == .left ? focused : focused + 1
    columns.insert(
      Column(window: source.activeWindow, width: source.width, isFullWidth: source.isFullWidth),
      at: target)
    focusedColumn = target
    return true
  }

  @discardableResult
  public mutating func toggleTabbed() -> Bool {
    guard let focused = focusedColumn, columns[focused].windows.count > 1 else { return false }
    columns[focused].display = columns[focused].display == .stacked ? .tabbed : .stacked
    return true
  }
}
