import CoreGraphics
import StripCore
import WindowSystem

final class OverlayPresenter {
  private static let tabBarSpacing: Double = 4
  private static let borderHidingDistance: CGFloat = 24
  private static let borderShowingDistance: CGFloat = 2

  private struct DimRequest: Equatable {
    var window: CGWindowID
    var amount: Double
    var displayFrames: [CGRect]
  }

  var onTabSelected: ((WindowID) -> Void)? {
    get { host.onTabSelected }
    set { host.onTabSelected = newValue }
  }

  private let state: TilingState
  private let source: any WindowSource
  private let store: PreferencesStore
  private let host: any OverlayHost
  private var tabTitles: [WindowID: String] = [:]
  private var shownDim: DimRequest?
  private var isBorderWaitingForWindow = false

  init(
    state: TilingState, source: any WindowSource, store: PreferencesStore,
    host: any OverlayHost
  ) {
    self.state = state
    self.source = source
    self.store = store
    self.host = host
  }

  func render(_ layouts: [Workspace.Key: StripLayout]) {
    let focused = focusedPlacement(in: layouts)
    renderFocusBorder(following: focused)
    renderDim(behind: focused)
    host.updateTabBars(tabBarModels(for: layouts))
  }

  func hide() {
    host.hideFocusBorder()
    host.hideDim()
    host.hideMinimap()
    host.updateTabBars([])
    shownDim = nil
  }

  func restackDim() {
    shownDim = nil
  }

  func refreshTitles() {
    tabTitles = [:]
    readTabTitles(onlyMissing: false)
  }

  func readMissingTitles() {
    readTabTitles(onlyMissing: true)
  }

  func flashMinimap(for key: Workspace.Key) {
    guard store.preferences.showsMinimap, let display = state.display(for: key),
      let workspace = state.workspaces[key], let layout = state.targetLayout(for: key),
      layout.contentWidth > state.usableWidth(of: display)
    else {
      host.hideMinimap()
      return
    }
    host.showMinimap(
      MinimapSnapshot(
        columns: minimapColumns(of: workspace, in: layout, on: display),
        contentWidth: layout.contentWidth,
        viewportOffset: workspace.scrollOffset,
        viewportWidth: state.usableWidth(of: display)),
      on: display.visibleFrame)
  }

  private func readTabTitles(onlyMissing: Bool) {
    for key in state.activeKeys {
      guard let strip = state.workspaces[key]?.strip else { continue }
      for column in strip.columns where column.display == .tabbed {
        for window in column.windows where !onlyMissing || tabTitles[window] == nil {
          tabTitles[window] = source.window(window.rawValue).map(Self.tabTitle)
        }
      }
    }
  }

  private static func tabTitle(of window: any WindowHandle) -> String {
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

  private func renderFocusBorder(following placement: Placement?) {
    guard store.preferences.showsFocusBorder, let placement else {
      isBorderWaitingForWindow = false
      host.hideFocusBorder()
      return
    }
    let target = targetFrame(of: placement)
    let gap = hypot(
      placement.frame.minX - target.minX, placement.frame.minY - target.minY)
    if gap > Self.borderHidingDistance {
      isBorderWaitingForWindow = true
    } else if gap <= Self.borderShowingDistance {
      isBorderWaitingForWindow = false
    }
    if isBorderWaitingForWindow {
      host.hideFocusBorder()
    } else {
      host.showFocusBorder(around: target, lineWidth: store.preferences.focusBorderWidth)
    }
  }

  private func targetFrame(of placement: Placement) -> CGRect {
    guard let key = state.activeKey(containing: placement.window),
      let target = state.targetLayout(for: key)?[placement.window]
    else { return placement.frame }
    return target.frame
  }

  private func renderDim(behind placement: Placement?) {
    guard store.preferences.dimsInactiveWindows, let placement else {
      if shownDim != nil { host.hideDim() }
      shownDim = nil
      return
    }
    let request = DimRequest(
      window: placement.window.rawValue,
      amount: store.preferences.dimAmount,
      displayFrames: state.tiledDisplays.map(\.frame))
    guard request != shownDim else { return }
    shownDim = request
    host.showDim(on: request.displayFrames, below: request.window, amount: request.amount)
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
