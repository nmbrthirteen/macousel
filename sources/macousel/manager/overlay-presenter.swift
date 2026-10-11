import CoreGraphics
import StripCore
import WindowSystem

final class OverlayPresenter {
  private static let tabBarSpacing: Double = 4

  private struct DimRequest: Equatable {
    var window: CGWindowID
    var amount: Double
    var displayFrames: [CGRect]
  }

  var onTabSelected: ((WindowID) -> Void)? {
    get { tabBars.onSelect }
    set { tabBars.onSelect = newValue }
  }

  private let state: TilingState
  private let tracker: WindowTracker
  private let store: PreferencesStore
  private let focusBorder = FocusBorderOverlay()
  private let dim = DimOverlay()
  private let minimap = MinimapOverlay()
  private let tabBars = TabBarOverlay()
  private var tabTitles: [WindowID: String] = [:]
  private var shownDim: DimRequest?

  init(state: TilingState, tracker: WindowTracker, store: PreferencesStore) {
    self.state = state
    self.tracker = tracker
    self.store = store
  }

  func render(_ layouts: [Workspace.Key: StripLayout]) {
    let focused = focusedPlacement(in: layouts)
    renderFocusBorder(around: focused)
    renderDim(behind: focused)
    tabBars.update(tabBarModels(for: layouts))
  }

  func hide() {
    focusBorder.hide()
    dim.hide()
    minimap.hide()
    tabBars.update([])
    shownDim = nil
  }

  func restackDim() {
    shownDim = nil
  }

  func refreshTitles() {
    tabTitles = [:]
    for key in state.activeKeys {
      guard let strip = state.workspaces[key]?.strip else { continue }
      for column in strip.columns where column.display == .tabbed {
        for window in column.windows {
          tabTitles[window] = tracker.windows[window.rawValue].map(Self.tabTitle)
        }
      }
    }
  }

  func flashMinimap(for key: Workspace.Key) {
    guard store.preferences.showsMinimap, let display = state.display(for: key),
      let workspace = state.workspaces[key], let layout = state.targetLayout(for: key),
      layout.contentWidth > state.usableWidth(of: display)
    else {
      minimap.hide()
      return
    }
    minimap.show(
      MinimapSnapshot(
        columns: minimapColumns(of: workspace, in: layout, on: display),
        contentWidth: layout.contentWidth,
        viewportOffset: workspace.scrollOffset,
        viewportWidth: state.usableWidth(of: display)),
      on: display.visibleFrame)
  }

  private static func tabTitle(of window: ManagedWindow) -> String {
    let title = window.title
    return title.isEmpty ? window.appName : title
  }

  private func focusedPlacement(in layouts: [Workspace.Key: StripLayout]) -> Placement? {
    guard let key = state.focusedKey, let display = state.display(for: key),
      let placement = layouts[key]?.placements.first(where: \.isFocused),
      !state.parkingPolicy(for: display).isParked(placement, in: display.visibleFrame)
    else { return nil }
    return placement
  }

  private func renderFocusBorder(around placement: Placement?) {
    guard store.preferences.showsFocusBorder, let placement else {
      focusBorder.hide()
      return
    }
    focusBorder.show(around: placement.frame, lineWidth: store.preferences.focusBorderWidth)
  }

  private func renderDim(behind placement: Placement?) {
    guard store.preferences.dimsInactiveWindows, let placement else {
      if shownDim != nil { dim.hide() }
      shownDim = nil
      return
    }
    let request = DimRequest(
      window: placement.window.rawValue,
      amount: store.preferences.dimAmount,
      displayFrames: state.tiledDisplays.map(\.frame))
    guard request != shownDim else { return }
    shownDim = request
    dim.show(on: request.displayFrames, below: request.window, amount: request.amount)
  }

  private func tabBarModels(for layouts: [Workspace.Key: StripLayout]) -> [TabBarModel] {
    state.activeKeys.flatMap { key -> [TabBarModel] in
      guard let display = state.display(for: key), let strip = state.workspaces[key]?.strip,
        let layout = layouts[key]
      else { return [] }
      let policy = state.parkingPolicy(for: display)
      return strip.columns.indices.compactMap { index in
        tabBarModel(for: strip.columns[index], at: index, in: layout, policy: policy, on: display)
      }
    }
  }

  private func tabBarModel(
    for column: Column, at index: Int, in layout: StripLayout, policy: ParkingPolicy,
    on display: Display
  ) -> TabBarModel? {
    guard column.display == .tabbed, column.windows.count > 1,
      let active = layout.placements.first(where: { $0.column == index && !$0.isBehindTab }),
      !policy.isParked(active, in: display.visibleFrame)
    else { return nil }
    let barHeight = state.config.tabBarHeight
    return TabBarModel(
      id: column.windows[0],
      frame: CGRect(
        x: active.frame.minX, y: active.frame.minY - barHeight,
        width: active.frame.width, height: barHeight - Self.tabBarSpacing),
      tabs: column.windows.map {
        TabBarModel.Tab(id: $0, title: tabTitles[$0] ?? "", isActive: $0 == active.window)
      })
  }

  private func minimapColumns(
    of workspace: Workspace, in layout: StripLayout, on display: Display
  ) -> [MinimapSnapshot.Column] {
    let stripOrigin = display.visibleFrame.minX + state.config.outerGap - workspace.scrollOffset
    return workspace.strip.columns.indices.compactMap { index in
      let rows = layout.placements.filter { $0.column == index }
      guard let first = rows.first else { return nil }
      let isTabbed = workspace.strip.columns[index].display == .tabbed
      return MinimapSnapshot.Column(
        x: first.frame.minX - stripOrigin,
        width: first.frame.width,
        rowShares: isTabbed ? [1] : rows.map { Double($0.frame.height) },
        isFocused: index == workspace.strip.focusedColumn)
    }
  }
}
