import CoreGraphics
import StripCore
import WindowSystem
import os

final class WindowReconciler {
  private static let signposter = OSSignposter(subsystem: "dev.macousel.app", category: "reconcile")

  private let state: TilingState
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let store: PreferencesStore
  private let probe: any WindowProbing
  private let restorer: WindowRestorer
  private let recorder: SessionRecorder
  private let admissionFrames: AdmissionFrames
  private let qualifier: WindowQualifier
  private let queue = ReconcileQueue()
  private let recents: RecentAppWindows
  private var absences = AbsenceTracker()
  private var previousActiveKeys: [Workspace.Key] = []
  private(set) var probedFacts: [CGWindowID: WindowFacts] = [:]

  init(
    state: TilingState, source: any WindowSource, environment: any DesktopEnvironment,
    store: PreferencesStore, probe: any WindowProbing, restorer: WindowRestorer,
    sessions: SessionStore, admissionFrames: AdmissionFrames, scratchpad: Scratchpad,
    recents: RecentAppWindows, now: @escaping () -> ContinuousClock.Instant
  ) {
    self.state = state
    self.source = source
    self.environment = environment
    self.store = store
    self.probe = probe
    self.restorer = restorer
    recorder = SessionRecorder(state: state, source: source, store: store, sessions: sessions)
    self.admissionFrames = admissionFrames
    qualifier = WindowQualifier(
      state: state, source: source, store: store, scratchpad: scratchpad, now: now)
    self.recents = recents
    queue.onRun = { [weak self] request in self?.run(request) }
  }

  var capturedTitles: [CGWindowID: String] { recorder.capturedTitles }
  var probedTitles: [CGWindowID: String] { probedFacts.mapValues(\.title) }

  func reconcile(
    adoptingFocus: Bool = true, refreshingTabTitles: Bool = true,
    then completion: @escaping () -> Void = {}
  ) {
    queue.submit(
      ReconcileRequest(
        adoptsFocus: adoptingFocus, refreshesTabTitles: refreshingTabTitles,
        completions: [completion]))
  }

  func cancelPending() {
    queue.cancel()
  }

  func invalidateFullScreen(_ window: CGWindowID) {
    qualifier.invalidateFullScreen(window)
  }

  func toggleFloating(_ window: CGWindowID) {
    qualifier.toggleFloating(window)
  }

  func scheduleSessionSave() {
    recorder.scheduleSave()
  }

  func saveSession() {
    recorder.save()
  }

  private func run(_ request: ReconcileRequest) {
    state.refreshDisplays()
    let targets = qualifier.probeTargets(
      onScreen: environment.onScreenWindowIDs(), refreshingTabTitles: request.refreshesTabTitles)
    let wantsFocus = request.adoptsFocus && !isFrontmostAppPaused
    guard !targets.isEmpty || wantsFocus else {
      settle(request, with: WindowProbeResult())
      return
    }
    let epoch = queue.epoch
    probe.probe(targets, includingFocus: wantsFocus) { [weak self] result in
      guard let self, queue.epoch == epoch else { return }
      settle(request, with: result)
    }
  }

  private func settle(_ request: ReconcileRequest, with result: WindowProbeResult) {
    let interval = Self.signposter.beginInterval("reconcile")
    qualifier.apply(result)
    probedFacts = result.facts.filter { !$0.value.timedOut }
    updateStrips(using: result.facts)
    if request.adoptsFocus { adoptSystemFocus(result.focusedWindow) }
    state.activeKeys.forEach(state.scrollToFocus)
    scheduleSessionSave()
    Self.signposter.endInterval("reconcile", interval)
    request.completions.forEach { $0() }
    queue.finish()
  }

  private func updateStrips(using facts: [CGWindowID: WindowFacts]) {
    state.refreshDisplays()
    let spaceIsSettled = state.activeKeys == previousActiveKeys
    previousActiveKeys = state.activeKeys
    let onScreen = environment.onScreenWindowIDs()
    let candidates = qualifier.candidates(onScreen: onScreen)
    removeWindows(candidates: Set(candidates.map { WindowID($0) }), onScreen: onScreen)
    admitNewcomers(among: candidates, facts: facts)
    if spaceIsSettled { removeFromInactiveWorkspaces(candidates) }
    retain(only: Set(source.windows.keys))
  }

  private var isFrontmostAppPaused: Bool {
    guard let frontmost = environment.frontmostProcessID else { return false }
    return qualifier.isPaused(frontmost)
  }

  private func removeWindows(candidates: Set<WindowID>, onScreen: Set<CGWindowID>) {
    let members = Set(state.activeKeys.flatMap { state.workspaces[$0]?.strip.windows ?? [] })
    let removals = absences.removals(among: members) { member in
      if candidates.contains(member) { return .present }
      guard let window = source.window(member.rawValue) else { return .closed }
      return onScreen.contains(member.rawValue) || qualifier.isExcluded(window)
        ? .excluded : .offScreen
    }
    guard !removals.isEmpty else { return }
    for key in state.activeKeys {
      for window in state.workspaces[key]?.strip.windows ?? [] where removals.contains(window) {
        state.workspaces[key]?.strip.remove(window)
      }
    }
  }

  private func admitNewcomers(
    among candidates: [any WindowHandle], facts: [CGWindowID: WindowFacts]
  ) {
    let placed = Set(state.activeKeys.flatMap { state.workspaces[$0]?.strip.windows ?? [] })
    let newcomers = candidates.filter { !placed.contains(WindowID($0)) }
    for (key, windows) in groupedByWorkspace(newcomers, facts: facts) {
      admit(windows, to: key, facts: facts)
    }
  }

  private func groupedByWorkspace(
    _ windows: [any WindowHandle], facts: [CGWindowID: WindowFacts]
  ) -> [(Workspace.Key, [any WindowHandle])] {
    var positioned: [Workspace.Key: [(window: any WindowHandle, x: CGFloat)]] = [:]
    for window in windows {
      guard let frame = facts[window.id]?.frame, let key = state.activeKey(at: frame.center)
      else { continue }
      admissionFrames.record(frame, for: window.id)
      positioned[key, default: []].append((window, frame.minX))
    }
    return state.activeKeys.compactMap { key in
      positioned[key].map { (key, $0.sorted { $0.x < $1.x }.map(\.window)) }
    }
  }

  private func admit(
    _ windows: [any WindowHandle], to key: Workspace.Key, facts: [CGWindowID: WindowFacts]
  ) {
    for window in windows {
      if let frame = facts[window.id]?.frame { restorer.remember(window, frame: frame) }
    }
    recorder.capture(windows, titles: facts.mapValues(\.title))

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
    qualifier.retain(only: alive)
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

  private func adoptSystemFocus(_ window: CGWindowID?) {
    guard !isFrontmostAppPaused, let focused = window.map({ WindowID($0) }) else { return }
    recents.note(focused)
    state.focusedKey = state.activeKey(containing: focused)
    if let key = state.focusedKey {
      state.workspaces[key]?.strip.focus(focused)
    }
  }
}
