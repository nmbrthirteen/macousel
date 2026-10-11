import Foundation

extension Strip {
  @discardableResult
  public mutating func stack(
    _ window: WindowID, ontoColumnOf target: WindowID, atRow row: Int
  ) -> Bool {
    guard window != target, let source = location(of: window),
      let destination = location(of: target)
    else { return false }
    if source.column == destination.column {
      columns[source.column].moveWindow(from: source.row, to: row)
      focusedColumn = source.column
      return true
    }
    let remainsInPlace = columns[source.column].windows.count > 1
    if remainsInPlace {
      columns[source.column].removeWindow(at: source.row)
    } else {
      columns.remove(at: source.column)
    }
    guard let targetColumn = columns.firstIndex(where: { $0.windows.contains(target) }) else {
      return false
    }
    columns[targetColumn].insertWindow(window, at: row)
    focusedColumn = targetColumn
    return true
  }
}
