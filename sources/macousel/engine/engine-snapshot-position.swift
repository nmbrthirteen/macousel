import StripCore
import WindowSystem

extension EngineSnapshot {
  var stripPosition: StripPosition? {
    let columns = tiledColumns
    guard let focused = focusedColumnIndex else { return nil }
    return StripPosition(
      columnCount: columns.columns.count, focusedIndex: focused,
      windowsInFocusedColumn: columns.columns[focused].windows.count)
  }

  func columnIndex(of window: WindowID) -> Int? {
    tiledColumns.columnIndex(of: window)
  }

  func display(in displays: [Display]) -> Display? {
    displays.first { $0.id == active.displayId } ?? displays.first { $0.isMain } ?? displays.first
  }
}
