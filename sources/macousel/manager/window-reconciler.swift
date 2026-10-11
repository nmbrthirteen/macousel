import CoreGraphics
import StripCore
import os

final class WindowReconciler {
  private static let signposter = OSSignposter(
    subsystem: "dev.macousel.app", category: "reconcile")

  private let state: TilingState
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let store: PreferencesStore
  private let restorer: WindowRestorer
  private let recorder: SessionRecorder
  private let admissionFrames: AdmissionFrames
  private let scratchpad: Scratchpad
  private let unresponsive: UnresponsiveApps
  private let fullScreen = FullScreenCache()
  private var absences = AbsenceTracker()
  private var previousActiveKeys: [Workspace.Key] = []
  private var floating: Set<CGWindowID> = []
  private var knownTileable: Set<CGWindowID> = []

  init(
    state: TilingState, source: any WindowSource, environment: any DesktopEnvironment,
    store: PreferencesStore, restorer: WindowRestorer, sessions: SessionStore,
    admissionFrames: AdmissionFrames, scratchpad: Scratchpad,
    now: @escaping () -> ContinuousClock.Instant
  ) {
    self.state = state
    self.source = source
    self.environment = environment
    self.store = store
    self.restorer = restorer
    recorder = SessionRecorder(state: state, source: source, store: store, sessions: sessions)
    self.admissionFrames = admissionFrames
    self.scratchpad = scratchpad
    unresponsive = UnresponsiveApps(now: now)
  }

  func reconcile() {
    let interval = Self.signposter.beginInterval("reconcile")
    defer { Self.signposter.endInterval("reconcile", interval) }
    state.refreshDisplays()
    let spaceIsSettled = state.activeKeys == previousActiveKeys
    previousActiveKeys = state.activeKeys
    let onScreen = environment.onScreenWindowIDs()
    let candidates = tileCandidates(onScreen: onScreen)
    removeWindows(candidates: Set(candidates.map { WindowID($0) }), onScreen: onScreen)
    admitNewcomers(among: candidates)
    if spaceIsSettled { removeFromInactiveWorkspaces(candidates) }
    retain(only: Set(source.windows.keys))
    adoptSystemFocus()
    state.activeKeys.forEach(state.scrollToFocus)
    scheduleSessionSave()
  }

  var capturedTitles: [CGWindowID: String] { recorder.capturedTitles }

  func invalidateFullScreen(_ window: CGWindowID) {
    fullScreen[window] = nil
  }

  func toggleFloating(_ window: CGWindowID) {
    if floating.remove(window) == nil { floating.insert(window) }
  }

  func scheduleSessionSave() {
    recorder.scheduleSave()
  }

  func saveSession() {
    recorder.save()
  }

  private func tileCandidates(onScreen: Set<CGWindowID>) -> [any WindowHandle] {
    let placed = placedWindows()
    return source.windows.values.filter { window in
      onScreen.contains(window.id) && !isExcludedFromTiling(window)
        && qualifies(window, alreadyPlaced: placed)
    }
  }

  private func placedWindows() -> Set<CGWindowID> {
    Set(
      state.activeKeys.flatMap { state.workspaces[$0]?.strip.windows ?? [] }.map(\.rawValue))
  }

  private func qualifies(_ window: any WindowHandle, alreadyPlaced placed: Set<CGWindowID>)
    -> Bool
  {
    if unresponsive.isPaused(window.pid) { return placed.contains(window.id) }
    let tileable = isTileable(window)
    if unresponsive.noteTimeout(of: window) { return placed.contains(window.id) }
    guard tileable else { return false }
    if let cached = fullScreen[window.id] { return !cached }
    let isFullScreen = window.isFullScreen
    if unresponsive.noteTimeout(of: window) { return placed.contains(window.id) }
    fullScreen[window.id] = isFullScreen
    return !isFullScreen
  }

  private func isTileable(_ window: any WindowHandle) -> Bool {
    if knownTileable.contains(window.id) { return true }
    guard window.isTileable else { return false }
    knownTileable.insert(window.id)
    return true
  }

  private func isExcludedFromTiling(_ window: any WindowHandle) -> Bool {
    floating.contains(window.id) || scratchpad.holds(window.id) || isRuledFloat(window)
  }

  private func isRuledFloat(_ window: any WindowHandle) -> Bool {
    store.preferences.rule(for: window.bundleIdentifier) == .float
  }

  private func removeWindows(candidates: Set<WindowID>, onScreen: Set<CGWindowID>) {
    let members = Set(state.activeKeys.flatMap { state.workspaces[$0]?.strip.windows ?? [] })
    let removals = absences.removals(among: members) { member in
      if candidates.contains(member) { return .present }
      guard let window = source.window(member.rawValue) else { return .closed }
      return onScreen.contains(member.rawValue) || isExcludedFromTiling(window)
        ? .excluded : .offScreen
    }
    guard !removals.isEmpty else { return }
    for key in state.activeKeys {
      for window in state.workspaces[key]?.strip.windows ?? [] where removals.contains(window) {
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
      let read = window.frame
      if unresponsive.noteTimeout(of: window) { continue }
      guard let frame = read, let key = state.activeKey(at: frame.center) else { continue }
      admissionFrames.record(frame, for: window.id)
      positioned[key, default: []].append((window, frame.minX))
    }
    return state.activeKeys.compactMap { key in
      positioned[key].map { (key, $0.sorted { $0.x < $1.x }.map(\.window)) }
    }
  }

  private func admit(_ windows: [any WindowHandle], to key: Workspace.Key) {
    windows.forEach(restorer.remember)
    recorder.capture(windows)
    for window in windows { unresponsive.noteTimeout(of: window) }

    var strip = state.workspaces[key]?.strip ?? Strip()
    if strip.isEmpty {
      populate(&strip, with: windows, displayUUID: key.displayUUID)
    } else {
      windows.forEach { insertBesideFocus($0, into: &strip) }
    }
    state.workspaces[key, default: Workspace()].strip = strip
  }

  private func removeFromInactiveWorkspaces(_ windows: [any WindowHandle]) {
    let active = Set(state.activeKeys)
    for key in state.workspaces.keys where !active.contains(key) {
      for window in windows {
        state.workspaces[key]?.strip.remove(WindowID(window))
      }
    }
  }

  private func populate(
    _ strip: inout Strip, with windows: [any WindowHandle], displayUUID: String
  ) {
    var remaining = windows
    if store.preferences.restoresSession, let saved = recorder.takeSaved(forDisplay: displayUUID) {
      remaining = strip.restore(saved, from: windows, titles: recorder.capturedTitles)
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
    fullScreen.retain(only: alive)
    scratchpad.retain(only: alive)
    unresponsive.pruneExpired()
    recorder.retain(only: alive)
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
    if let frontmost = environment.frontmostProcessID, unresponsive.isPaused(frontmost) { return }
    guard let focused = source.focusedWindow().map({ WindowID($0) }) else { return }
    state.focusedKey = state.activeKey(containing: focused)
    if let key = state.focusedKey {
      state.workspaces[key]?.strip.focus(focused)
    }
  }
}
