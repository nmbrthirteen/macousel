import StripCore

nonisolated struct StripPosition: Equatable, Sendable {
  let columnCount: Int
  let focusedIndex: Int
  let windowsInFocusedColumn: Int

  var columnNumber: Int { focusedIndex + 1 }

  init(columnCount: Int, focusedIndex: Int, windowsInFocusedColumn: Int) {
    self.columnCount = columnCount
    self.focusedIndex = focusedIndex
    self.windowsInFocusedColumn = windowsInFocusedColumn
  }

  init?(strip: Strip) {
    guard let focused = strip.focusedColumn, strip.columns.indices.contains(focused) else {
      return nil
    }
    self.init(
      columnCount: strip.columns.count, focusedIndex: focused,
      windowsInFocusedColumn: strip.columns[focused].windows.count)
  }
}
