import CoreGraphics
import StripCore
import WindowSystem

final class WindowQualifier {
  private let state: TilingState
  private let source: any WindowSource
  private let store: PreferencesStore
  private let scratchpad: Scratchpad
  private let unresponsive: UnresponsiveApps
  private let fullScreen = FullScreenCache()
  private var tileability: TileabilityCache
  private var floating: Set<CGWindowID> = []

  init(
    state: TilingState, source: any WindowSource, store: PreferencesStore,
    scratchpad: Scratchpad, now: @escaping () -> ContinuousClock.Instant
  ) {
    self.state = state
    self.source = source
    self.store = store
    self.scratchpad = scratchpad
    tileability = TileabilityCache(now: now)
    unresponsive = UnresponsiveApps(now: now)
  }

  func isPaused(_ pid: pid_t) -> Bool {
    unresponsive.isPaused(pid)
  }

  func isExcluded(_ window: any WindowHandle) -> Bool {
    floating.contains(window.id) || scratchpad.holds(window.id)
      || store.preferences.rule(for: window.bundleIdentifier) == .float
  }

  func invalidateFullScreen(_ window: CGWindowID) {
    fullScreen[window] = nil
  }

  func toggleFloating(_ window: CGWindowID) {
    if floating.remove(window) == nil { floating.insert(window) }
  }

  func probeTargets(onScreen: Set<CGWindowID>, refreshingTabTitles: Bool) -> [CGWindowID] {
    let placed = placedWindows()
    let tabbed = refreshingTabTitles ? tabbedWindows() : []
    return source.windows.values.filter { window in
      onScreen.contains(window.id) && !isExcluded(window) && !unresponsive.isPaused(window.pid)
        && (needsFacts(window.id, placed: placed) || tabbed.contains(window.id))
    }.map(\.id).sorted()
  }

  func apply(_ result: WindowProbeResult) {
    for (id, facts) in result.facts {
      guard let window = source.window(id) else { continue }
      if facts.timedOut {
        unresponsive.noteTimeout(ofApp: window.pid)
        continue
      }
      tileability.record(id, isTileable: facts.isTileable)
      if facts.isTileable { fullScreen[id] = facts.isFullScreen }
    }
  }

  func candidates(onScreen: Set<CGWindowID>) -> [any WindowHandle] {
    let placed = placedWindows()
    return source.windows.values.filter { window in
      onScreen.contains(window.id) && !isExcluded(window) && qualifies(window, placed: placed)
    }
  }

  func retain(only alive: Set<CGWindowID>) {
    floating.formIntersection(alive)
    tileability.retain(only: alive)
    fullScreen.retain(only: alive)
    unresponsive.pruneExpired()
    scratchpad.retain(only: alive)
  }

  private func needsFacts(_ window: CGWindowID, placed: Set<CGWindowID>) -> Bool {
    switch tileability.answer(for: window) {
    case nil: true
    case false: false
    case true: fullScreen[window].map { !$0 && !placed.contains(window) } ?? true
    }
  }

  private func qualifies(_ window: any WindowHandle, placed: Set<CGWindowID>) -> Bool {
    let isPlaced = placed.contains(window.id)
    if unresponsive.isPaused(window.pid) { return isPlaced }
    guard let isTileable = tileability.answer(for: window.id) else { return isPlaced }
    guard isTileable else { return false }
    return fullScreen[window.id].map { !$0 } ?? isPlaced
  }

  private func placedWindows() -> Set<CGWindowID> {
    Set(state.activeKeys.flatMap { state.workspaces[$0]?.strip.windows ?? [] }.map(\.rawValue))
  }

  private func tabbedWindows() -> Set<CGWindowID> {
    Set(
      state.activeKeys.flatMap { key in
        (state.workspaces[key]?.strip.columns ?? []).filter { $0.display == .tabbed }
          .flatMap(\.windows)
      }.map(\.rawValue))
  }
}
