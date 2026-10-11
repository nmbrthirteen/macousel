import CoreGraphics
import StripCore
import WindowSystem

final class TilingState {
  private(set) var displays: [Display] = []
  private(set) var activeKeys: [Workspace.Key] = []
  var workspaces: [Workspace.Key: Workspace] = [:]
  var focusedKey: Workspace.Key?

  private let store: PreferencesStore

  init(store: PreferencesStore) {
    self.store = store
  }

  var config: LayoutConfig { store.preferences.layout }

  var tiledDisplays: [Display] {
    displays.filter { !store.preferences.disabledDisplays.contains($0.uuid) }
  }

  var pointerKey: Workspace.Key? { activeKey(at: Pointer.location) }

  func refreshDisplays() {
    displays = Display.all()
    activeKeys = tiledDisplays.map(Workspace.Key.init(currentSpaceOf:))
    for key in activeKeys where workspaces[key] == nil {
      workspaces[key] = Workspace()
    }
  }

  func discardEmptyInactiveWorkspaces() {
    let active = Set(activeKeys)
    workspaces = workspaces.filter { active.contains($0.key) || !$0.value.strip.isEmpty }
  }

  func display(for key: Workspace.Key) -> Display? {
    displays.first { $0.uuid == key.displayUUID }
  }

  func activeKey(for display: Display) -> Workspace.Key? {
    activeKeys.first { $0.displayUUID == display.uuid }
  }

  func activeKey(containing window: WindowID) -> Workspace.Key? {
    activeKeys.first { workspaces[$0]?.strip.contains(window) == true }
  }

  func activeKey(at point: CGPoint) -> Workspace.Key? {
    nearestTiledDisplay(to: point).flatMap(activeKey(for:))
  }

  func nearestTiledDisplay(to point: CGPoint) -> Display? {
    guard let nearest = displays.min(by: {
      $0.frame.squaredDistance(to: point) < $1.frame.squaredDistance(to: point)
    }) else { return nil }
    return tiledDisplays.contains(nearest) ? nearest : nil
  }

  func usableWidth(of display: Display) -> Double {
    display.visibleFrame.width - 2 * config.outerGap
  }

  func parkingPolicy(for display: Display) -> ParkingPolicy {
    ParkingPolicy(
      displayBounds: display.frame,
      hasLeftNeighbor: display.hasNeighbor(.left, among: displays),
      hasRightNeighbor: display.hasNeighbor(.right, among: displays))
  }

  func scrollRange(of key: Workspace.Key) -> ClosedRange<Double> {
    guard let display = display(for: key), let layout = settledLayout(for: key) else {
      return 0...0
    }
    let usableWidth = usableWidth(of: display)
    let furthest = max(layout.contentWidth - usableWidth, 0)
    guard config.centerMode == .always else { return 0...furthest }
    return (-usableWidth / 2)...(max(layout.contentWidth - usableWidth / 2, 0))
  }

  func scrollToFocus(_ key: Workspace.Key) {
    guard let display = display(for: key) else { return }
    workspaces[key]?.strip.scrollToFocus(
      viewportWidth: display.visibleFrame.width, config: config)
  }

  func targetLayout(for key: Workspace.Key) -> StripLayout? {
    layout(for: key, scrollOffset: workspaces[key]?.gestureOffset)
  }

  func animatedLayout(for key: Workspace.Key) -> StripLayout? {
    guard let target = targetLayout(for: key), let display = display(for: key) else { return nil }
    return workspaces[key]?.motion.animated(target, in: display.visibleFrame)
  }

  func settledLayout(for key: Workspace.Key) -> StripLayout? {
    layout(for: key, scrollOffset: nil)
  }

  private func layout(for key: Workspace.Key, scrollOffset: Double?) -> StripLayout? {
    guard let workspace = workspaces[key], let display = display(for: key) else { return nil }
    return workspace.strip.layout(
      in: display.visibleFrame, config: config, scrollOffset: scrollOffset)
  }
}

extension CGRect {
  var center: CGPoint { CGPoint(x: midX, y: midY) }

  func squaredDistance(to point: CGPoint) -> CGFloat {
    let horizontal = max(minX - point.x, 0, point.x - maxX)
    let vertical = max(minY - point.y, 0, point.y - maxY)
    return horizontal * horizontal + vertical * vertical
  }

  func isClose(to other: CGRect, within tolerance: CGFloat) -> Bool {
    abs(minX - other.minX) <= tolerance && abs(minY - other.minY) <= tolerance
      && abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
  }

  func clamped(into bounds: CGRect) -> CGRect {
    var result = self
    result.origin.x = min(max(minX, bounds.minX), max(bounds.minX, bounds.maxX - width))
    result.origin.y = min(max(minY, bounds.minY), max(bounds.minY, bounds.maxY - height))
    return result
  }
}
