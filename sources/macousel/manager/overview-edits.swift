import StripCore

struct OverviewEdits {
  let state: TilingState

  func move(_ window: WindowID, to target: DropTarget, in key: Workspace.Key) -> Bool {
    edit(key) { strip in
      strip = DropRule.applying(target, moving: window, to: strip)
      return true
    }
  }

  func nudge(_ window: WindowID, _ direction: Direction, in key: Workspace.Key) -> Bool {
    edit(key) { strip in
      strip.focus(window)
      return strip.moveFocused(direction)
    }
  }

  func moveToPlace(_ window: WindowID, _ place: Int, in key: Workspace.Key) -> Bool {
    edit(key) { strip in
      strip.focus(window)
      return strip.moveFocusedToPlace(place)
    }
  }

  func widen(_ window: WindowID, by delta: Double, in key: Workspace.Key) -> Bool {
    guard let display = state.display(for: key) else { return false }
    return edit(key) { strip in
      strip.focus(window)
      return strip.adjustWidth(
        by: delta, viewportWidth: display.visibleFrame.width, config: state.config)
    }
  }

  func setWidthFraction(_ fraction: Double, of window: WindowID, in key: Workspace.Key) -> Bool {
    edit(key) { $0.setWidthFraction(fraction, ofColumnContaining: window) }
  }

  func setHeightShare(
    _ share: Double, of window: WindowID, borrowingFrom neighbor: VerticalNeighbor,
    in key: Workspace.Key
  ) -> Bool {
    guard let display = state.display(for: key), let strip = state.workspaces[key]?.strip,
      let column = strip.columnIndex(of: window)
    else { return false }
    let config = state.config
    let rows = Double(strip.columns[column].windows.count)
    let rowsHeight = display.visibleFrame.height - 2 * config.outerGap - (rows - 1) * config.innerGap
    return edit(key) {
      $0.setHeight(
        share * rowsHeight, of: window, borrowingFrom: neighbor,
        viewportHeight: display.visibleFrame.height, config: config)
    }
  }

  private func edit(_ key: Workspace.Key, _ change: (inout Strip) -> Bool) -> Bool {
    guard var strip = state.workspaces[key]?.strip else { return false }
    let before = strip
    let focus = strip.focusedWindow
    guard change(&strip) else { return false }
    if let focus { strip.focus(focus) }
    guard strip != before else { return false }
    state.workspaces[key]?.strip = strip
    state.scrollToFocus(key)
    return true
  }
}
