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
  private let minimapBuilder: MinimapSnapshotBuilder
  private var tabTitles: [WindowID: String] = [:]
  private var shownDim: DimRequest?
  private var isBorderWaitingForWindow = false

  init(
    state: TilingState, source: any WindowSource, store: PreferencesStore,
    environment: any DesktopEnvironment, host: any OverlayHost
  ) {
    self.state = state
    self.source = source
    self.store = store
    self.host = host
    minimapBuilder = MinimapSnapshotBuilder(
      state: state, source: source, store: store, environment: environment)
  }

  func render(_ layouts: [Workspace.Key: StripLayout]) {
    let focused = focusedPlacement(in: layouts)
    renderFocusBorder(following: focused)
    renderDim(behind: focused)
    host.updateTabBars(tabBarModels(for: layouts))
  }

  func showDropPreview(at frame: CGRect) {
    host.showDropPreview(at: frame)
  }

  func hideDropPreview() {
    host.hideDropPreview()
  }

  func hide() {
    host.hideDropPreview()
    host.hideFocusBorder()
    host.hideDim()
    host.hideMinimap()
    host.updateTabBars([])
    shownDim = nil
  }

  func restackDim() {
    shownDim = nil
  }

  func refreshTitles(using probed: [CGWindowID: String]) {
    let tabbed = tabbedWindows()
    tabTitles = tabTitles.filter { tabbed.contains($0.key) }
    for window in tabbed {
      guard let title = probed[window.rawValue], let handle = source.window(window.rawValue)
      else { continue }
      tabTitles[window] = Self.tabTitle(title, of: handle)
    }
  }

  func rereadTitles() {
    tabTitles = [:]
    readMissingTitles()
  }

  func readMissingTitles() {
    for window in tabbedWindows() where tabTitles[window] == nil {
      tabTitles[window] = source.window(window.rawValue).map { Self.tabTitle($0.title, of: $0) }
    }
  }

  func flashMinimap(for key: Workspace.Key, update: MinimapUpdate) {
    guard store.preferences.showsMinimap, let display = state.display(for: key),
      let snapshot = minimapBuilder.snapshot(for: key, on: display)
    else {
      host.hideMinimap()
      return
    }
    host.showMinimap(snapshot, update: update, on: display.visibleFrame)
  }

  private func tabbedWindows() -> Set<WindowID> {
    Set(
      state.activeKeys.flatMap { key in
        (state.workspaces[key]?.strip.columns ?? []).filter { $0.display == .tabbed }
          .flatMap(\.windows)
      })
  }

  private static func tabTitle(_ title: String, of window: any WindowHandle) -> String {
    title.isEmpty ? window.appName : title
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
}
