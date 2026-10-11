import StripCore
import WindowSystem

struct MinimapSnapshotBuilder {
  let state: TilingState
  let source: any WindowSource
  let store: PreferencesStore
  let environment: any DesktopEnvironment

  func snapshot(for key: Workspace.Key, on display: Display) -> MinimapSnapshot? {
    guard let workspace = state.workspaces[key], let layout = state.targetLayout(for: key),
      layout.contentWidth > state.usableWidth(of: display)
    else { return nil }
    return MinimapSnapshot(
      columns: columns(of: workspace, in: layout, on: display),
      contentWidth: layout.contentWidth,
      viewportOffset: workspace.scrollOffset,
      viewportWidth: state.usableWidth(of: display),
      animationResponse: animationResponse, innerGap: state.config.innerGap)
  }

  private var animationResponse: Double? {
    guard !environment.reducesMotion, !environment.isLowPowerModeEnabled else { return nil }
    return store.preferences.animationSpeed.springResponse
  }

  private func columns(
    of workspace: Workspace, in layout: StripLayout, on display: Display
  ) -> [MinimapSnapshot.Column] {
    let stripOrigin = display.visibleFrame.minX + state.config.outerGap - workspace.scrollOffset
    return workspace.strip.columns.indices.compactMap { index in
      let column = workspace.strip.columns[index]
      let placements = layout.placements.filter { $0.column == index }
      guard let first = placements.first else { return nil }
      return MinimapSnapshot.Column(
        x: first.frame.minX - stripOrigin,
        width: first.frame.width,
        rows: placements.map { placement in
          MinimapSnapshot.Row(
            window: placement.window,
            bundleIdentifier: source.window(placement.window.rawValue)?.bundleIdentifier,
            height: Double(placement.frame.height))
        },
        activeRow: column.activeRow,
        isTabbed: column.display == .tabbed,
        isFocused: index == workspace.strip.focusedColumn)
    }
  }
}
