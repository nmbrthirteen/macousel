import StripCore

struct EngineMinimapBuilder {
  static let cellWidth = 400.0

  let snapshot: EngineSnapshot

  func build() -> MinimapSnapshot? {
    let windows = snapshot.tiledWindows
    let visible = windows.indices.filter { windows[$0].visible }
    guard windows.count > 1, let first = visible.first, visible.count < windows.count else {
      return nil
    }
    let focused = snapshot.focusedColumnIndex
    return MinimapSnapshot(
      columns: windows.indices.compactMap { index in
        column(for: windows[index], at: index, isFocused: index == focused)
      },
      contentWidth: Double(windows.count) * Self.cellWidth,
      viewportOffset: Double(first) * Self.cellWidth,
      viewportWidth: Double(visible.count) * Self.cellWidth, animationResponse: nil)
  }

  private func column(for window: EngineWindow, at index: Int, isFocused: Bool)
    -> MinimapSnapshot.Column?
  {
    guard let id = EngineWindowID.make(window.windowId) else { return nil }
    return MinimapSnapshot.Column(
      x: Double(index) * Self.cellWidth, width: Self.cellWidth,
      rows: [MinimapSnapshot.Row(window: id, bundleIdentifier: window.bundleId, height: 1)],
      activeRow: 0, isTabbed: false, isFocused: isFocused)
  }
}
