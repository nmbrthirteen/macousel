import CoreGraphics
import Observation
import StripCore
import WindowSystem
import os

@Observable
final class PaneruEngine: ManagementEngine {
  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  private(set) var status = WindowManager.Status.needsPermission
  private(set) var displays: [Display] = []

  @ObservationIgnored private let parts: PaneruEngineParts
  @ObservationIgnored private let accessibility: AccessibilityMonitor
  @ObservationIgnored private var appliedInputs: InputSettings?
  @ObservationIgnored private var focusHistory = FocusHistory()

  init(_ parts: PaneruEngineParts) {
    self.parts = parts
    accessibility = AccessibilityMonitor(environment: parts.environment)
    parts.supervisor.onStateChange = { [weak self] state in self?.supervisorChanged(state) }
    parts.events.onEvent = { [weak self] event in self?.parts.world.handle(event) }
    parts.events.onConnect = { [weak self] in self?.parts.world.refresh() }
    parts.world.onFocusMoved = { [weak self] snapshot in
      if self?.parts.overview.isOpen == false { self?.parts.minimap.flash(snapshot) }
    }
    parts.world.onAdopted = { [weak self] snapshot in self?.adopted(snapshot) }
    parts.floating.isSuppressed = { [overview = parts.overview] in overview.isOpen }
  }

  var position: StripPosition? { parts.world.position }

  var notice: String? { parts.supervisor.state.failure?.message }

  func report(selected: WindowEngine) async -> EngineReport {
    await parts.reporter.report(selected: selected)
  }

  func start() {
    displays = parts.environment.displays
    if parts.environment.isAccessibilityGranted { begin() } else { awaitAccessibility() }
  }

  func perform(_ action: Action) {
    switch (action.paneruSupport, status) {
    case (_, .needsPermission):
      Self.logger.info("Dropped \(action.commandName, privacy: .public): no Accessibility access")
    case (.handledByMacousel, _):
      performLocally(action)
    case (.command(let command), .running):
      parts.overview.close()
      send(command)
    default:
      Self.logger.info("Dropped \(action.commandName, privacy: .public) for the engine")
    }
  }

  func shutdown() {
    accessibility.stop()
    stopEngine()
    parts.bindings.release()
    status = .needsPermission
  }

  func preferencesChanged() {
    guard status != .needsPermission else { return }
    if parts.supervisor.state == .running {
      do {
        try parts.sync.writeIfChanged()
      } catch {
        Self.logger.error("Could not rewrite the engine configuration: \(error, privacy: .public)")
      }
    }
    if !parts.store.preferences.showsMinimap { parts.minimap.hide() }
    guard currentInputs != appliedInputs else { return }
    parts.swipe.configure(isRunning: status == .running)
    applyBindings()
  }

  private func adopted(_ snapshot: EngineSnapshot) {
    parts.overview.refresh(with: snapshot)
    parts.floating.adopted(snapshot)
    // A reorder walks focus through other windows on its way, which is not the user's focus.
    if !parts.reorder.isRunning, let focused = snapshot.active.focusedWindowId,
      let window = CGWindowID(exactly: focused)
    {
      focusHistory.note(window)
    }
  }

  private func performLocally(_ action: Action) {
    switch (action, status) {
    case (.togglePaused, .running): pause()
    case (.togglePaused, .paused): begin()
    case (.toggleOverview, .running): parts.overview.toggle(with: parts.world.snapshot)
    case (.moveToColumn(let place), .running):
      parts.overview.close()
      Task { _ = await parts.reorder.moveFocused(toPlace: place) }
    case (.focusPrevious, .running):
      parts.overview.close()
      focusPreviousWindow()
    case (.bringBackFloatingWindows, .running):
      Task { await bringBackFloatingWindows() }
    case (.popOutLeft, .running) where !isFocusedWindowStacked:
      Self.logger.info("Dropped \(action.commandName, privacy: .public): not in a stack")
    case (_, .running) where action.paneruSequence != nil:
      parts.overview.close()
      let sequence = action.paneruSequence ?? []
      Task {
        for command in sequence { await parts.commands.send(command.words) }
      }
    default: Self.logger.info("Dropped \(action.commandName, privacy: .public): paused")
    }
  }

  private func begin() {
    status = .running
    parts.supervisor.start()
    parts.drag.start()
    parts.swipe.configure(isRunning: true)
    applyBindings()
    accessibility.watchForLoss { [weak self] in self?.accessibilityLost() }
  }

  private func pause() {
    status = .paused
    stopEngine()
    applyBindings()
  }

  private func accessibilityLost() {
    Self.logger.error("Accessibility access was lost, the engine stopped")
    stopEngine()
    status = .needsPermission
    parts.bindings.release()
    awaitAccessibility()
  }

  private func awaitAccessibility() {
    status = .needsPermission
    parts.environment.requestAccessibilityAccess()
    accessibility.waitForGrant { [weak self] in self?.begin() }
  }

  private func stopEngine() {
    parts.drag.stop()
    parts.swipe.stop()
    parts.overview.close()
    parts.minimap.hide()
    parts.events.stop()
    parts.world.clear()
    parts.floating.cancel()
    parts.supervisor.stop()
    parts.sync.forget()
  }

  private func supervisorChanged(_ state: EngineRunState) {
    switch state {
    case .running:
      parts.events.start()
      parts.world.connect()
    case .failed:
      parts.drag.stop()
      parts.swipe.stop()
      parts.events.stop()
      parts.world.clear()
      status = .paused
      applyBindings()
    case .needsPermission:
      awaitAccessibility()
    case .waitingToRestart:
      parts.events.stop()
    case .stopped, .starting:
      break
    }
  }

  private var currentInputs: InputSettings {
    parts.store.preferences.inputSettings(
      isRecordingShortcut: parts.store.isRecordingShortcut, isActive: status == .running)
  }

  private func applyBindings() {
    appliedInputs = currentInputs
    parts.bindings.apply(
      isRunning: status == .running, perform: { [weak self] action in self?.perform(action) },
      jump: { [weak self] bundle in self?.parts.appShortcuts.jump(to: bundle) })
  }

  private var isFocusedWindowStacked: Bool {
    guard let snapshot = parts.world.snapshot, let focused = snapshot.focusedWindowID else {
      return false
    }
    return (snapshot.tiledColumns.column(of: focused)?.windows.count ?? 0) > 1
  }

  private func focusPreviousWindow() {
    guard let previous = focusHistory.previous, let snapshot = parts.world.snapshot else { return }
    let id = WindowID(previous)
    if snapshot.tiledColumns.position(of: id) != nil {
      Task { await parts.reorder.focus(id) }
    } else if snapshot.floatingWindows.contains(where: { EngineWindowID.make($0.windowId) == id }) {
      parts.windows.focus(previous)
    } else {
      Self.logger.info("Dropped focus-previous: the window is gone")
    }
  }

  private func bringBackFloatingWindows() async {
    let displays = parts.environment.displays
    guard let snapshot = await parts.commands.fetchSnapshot(),
      let display = snapshot.display(in: displays)
    else { return }
    let screens = displays.map(\.frame)
    for window in snapshot.activeFloatingWindows {
      guard let id = CGWindowID(exactly: window.windowId), let frame = window.frame?.rect,
        let target = FloatingRecovery.frame(
          for: frame, displays: screens, into: display.visibleFrame)
      else { continue }
      parts.windows.move(id, to: target)
    }
  }

  private func send(_ command: PaneruCommand) {
    Task { await parts.commands.send(command.words) }
  }
}
