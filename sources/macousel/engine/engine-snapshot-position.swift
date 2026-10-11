import StripCore
import WindowSystem

extension EngineSnapshot {
  var stripPosition: StripPosition? {
    guard let focused = focusedColumnIndex else { return nil }
    return StripPosition(
      columnCount: tiledWindows.count, focusedIndex: focused, windowsInFocusedColumn: 1)
  }

  func columnIndex(of window: WindowID) -> Int? {
    tiledWindows.firstIndex { EngineWindowID.make($0.windowId) == window }
  }

  func display(in displays: [Display]) -> Display? {
    displays.first { $0.id == active.displayId } ?? displays.first { $0.isMain } ?? displays.first
  }
}
