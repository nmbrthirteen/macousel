import CoreGraphics
import StripCore
import os

final class WindowReconciler {
  private static let sessionSaveDelay = Duration.seconds(2)
  private static let signposter = OSSignposter(
    subsystem: "dev.macousel.app", category: "reconcile")

  private let state: TilingState
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let store: PreferencesStore
  private let restorer: WindowRestorer
  private let sessions: SessionStore
  private var floating: Set<CGWindowID> = []
  private var knownTileable: Set<CGWindowID> = []
  private var capturedTitles: [CGWindowID: String] = [:]
  private var savedSession: [String: [SavedColumn]]
  private var pendingSessionSave: Task<Void, Never>?

  init(
    state: TilingState, source: any WindowSource, environment: any DesktopEnvironment,
    store: PreferencesStore, restorer: WindowRestorer, sessions: SessionStore
  ) {
    self.state = state
    self.source = source
    self.environment = environment
    self.store = store
    self.restorer = restorer
    self.sessions = sessions
    savedSession = sessions.load()
  }

  func reconcile() {
    let interval = Self.signposter.beginInterval("reconcile")
    defer { Self.signposter.endInterval("reconcile", interval) }
    state.refreshDisplays()
    let candidates = tileCandidates()
    removeWindows(notIn: Set(candidates.map { WindowID($0) }))
    admitNewcomers(among: candidates)
    retain(only: Set(source.windows.keys))
    adoptSystemFocus()
    state.activeKeys.forEach(state.scrollToFocus)
    scheduleSessionSave()
  }

  func toggleFloating(_ window: CGWindowID) {
    if floating.remove(window) == nil { floating.insert(window) }
  }

  func scheduleSessionSave() {
    pendingSessionSave?.cancel()
    pendingSessionSave = Task {
      try? await Task.sleep(for: Self.sessionSaveDelay)
      if !Task.isCancelled { saveSession() }
    }
  }

  func saveSession() {
    pendingSessionSave?.cancel()
    guard store.preferences.restoresSession else { return }
    let stripsByDisplay = state.activeKeys.reduce(into: [String: Strip]()) { strips, key in
      strips[key.displayUUID] = state.workspaces[key]?.strip
    }
    sessions.save(stripsByDisplay, windows: source.windows, titles: capturedTitles)
  }

  private func tileCandidates() -> [any WindowHandle] {
    let onScreen = environment.onScreenWindowIDs()
    return source.windows.values.filter { window in
      onScreen.contains(window.id) && !floating.contains(window.id)
        && store.preferences.rule(for: window.bundleIdentifier) != .float
        && isTileable(window) && !window.isFullScreen
    }
  }

  private func isTileable(_ window: any WindowHandle) -> Bool {
    if knownTileable.contains(window.id) { return true }
    guard window.isTileable else { return false }
    knownTileable.insert(window.id)
    return true
  }

  private func removeWindows(notIn candidates: Set<WindowID>) {
    for key in state.activeKeys {
      guard let windows = state.workspaces[key]?.strip.windows else { continue }
      for window in windows where !candidates.contains(window) {
        state.workspaces[key]?.strip.remove(window)
      }
    }
  }

  private func admitNewcomers(among candidates: [any WindowHandle]) {
    let placed = Set(state.activeKeys.flatMap { state.workspaces[$0]?.strip.windows ?? [] })
    let newcomers = candidates.filter { !placed.contains(WindowID($0)) }
    for (key, windows) in groupedByWorkspace(newcomers) {
      admit(windows, to: key)
    }
  }

  private func groupedByWorkspace(_ windows: [any WindowHandle])
    -> [(Workspace.Key, [any WindowHandle])]
  {
    var positioned: [Workspace.Key: [(window: any WindowHandle, x: CGFloat)]] = [:]
    for window in windows {
      guard let frame = window.frame, let key = state.activeKey(at: frame.center) else { continue }
      positioned[key, default: []].append((window, frame.minX))
    }
    return state.activeKeys.compactMap { key in
      positioned[key].map { (key, $0.sorted { $0.x < $1.x }.map(\.window)) }
    }
  }

  private func admit(_ windows: [any WindowHandle], to key: Workspace.Key) {
    windows.forEach(restorer.remember)
    windows.forEach { capturedTitles[$0.id] = $0.title }
    removeFromOtherWorkspaces(windows, keeping: key)

    var strip = state.workspaces[key]?.strip ?? Strip()
    if strip.isEmpty {
      populate(&strip, with: windows, displayUUID: key.displayUUID)
    } else {
      windows.forEach { insertBesideFocus($0, into: &strip) }
    }
    state.workspaces[key, default: Workspace()].strip = strip
  }

  private func removeFromOtherWorkspaces(
    _ windows: [any WindowHandle], keeping key: Workspace.Key
  ) {
    for other in state.workspaces.keys where other != key {
      for window in windows {
        state.workspaces[other]?.strip.remove(WindowID(window))
      }
    }
  }

  private func populate(
    _ strip: inout Strip, with windows: [any WindowHandle], displayUUID: String
  ) {
    var remaining = windows
    if store.preferences.restoresSession,
      let saved = savedSession.removeValue(forKey: displayUUID)
    {
      remaining = strip.restore(saved, from: windows, titles: capturedTitles)
    }
    for window in remaining {
      strip.append(WindowID(window), width: initialWidth(for: window))
    }
    remaining.forEach { moveToRuledSlot($0, in: &strip) }
  }

  private func moveToRuledSlot(_ window: any WindowHandle, in strip: inout Strip) {
    guard case .slot(let position) = store.preferences.rule(for: window.bundleIdentifier)
    else { return }
    strip.move(WindowID(window), toColumn: position - 1)
  }

  private func insertBesideFocus(_ window: any WindowHandle, into strip: inout Strip) {
    let previousFocus = strip.focusedWindow
    strip.insert(WindowID(window), width: initialWidth(for: window), config: state.config)
    moveToRuledSlot(window, in: &strip)
    if !isFrontmost(window), let previousFocus {
      strip.focus(previousFocus)
    }
  }

  private func initialWidth(for window: any WindowHandle) -> ColumnWidth {
    if case .width(let fraction) = store.preferences.rule(for: window.bundleIdentifier) {
      return .fraction(fraction)
    }
    return .fraction(state.config.defaultWidth)
  }

  private func isFrontmost(_ window: any WindowHandle) -> Bool {
    environment.frontmostProcessID == window.pid
  }

  private func retain(only alive: Set<CGWindowID>) {
    floating.formIntersection(alive)
    knownTileable.formIntersection(alive)
    capturedTitles = capturedTitles.filter { alive.contains($0.key) }
    restorer.retain(only: alive)
    for key in state.workspaces.keys {
      guard let windows = state.workspaces[key]?.strip.windows else { continue }
      for window in windows where !alive.contains(window.rawValue) {
        state.workspaces[key]?.strip.remove(window)
      }
    }
    state.discardEmptyInactiveWorkspaces()
  }

  private func adoptSystemFocus() {
    guard let focused = source.focusedWindow().map({ WindowID($0) }) else { return }
    state.focusedKey = state.activeKey(containing: focused)
    if let key = state.focusedKey {
      state.workspaces[key]?.strip.focus(focused)
    }
  }
}
