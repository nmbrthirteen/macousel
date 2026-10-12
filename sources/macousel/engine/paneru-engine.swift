import Observation
import WindowSystem
import os

@Observable
final class PaneruEngine: ManagementEngine {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "engine")

  private(set) var status = WindowManager.Status.needsPermission
  private(set) var displays: [Display] = []

  @ObservationIgnored private let parts: PaneruEngineParts
  @ObservationIgnored private let accessibility: AccessibilityMonitor

  init(_ parts: PaneruEngineParts) {
    self.parts = parts
    accessibility = AccessibilityMonitor(environment: parts.environment, intervals: parts.polling)
    parts.supervisor.onStateChange = { [weak self] state in self?.supervisorChanged(state) }
    parts.events.onEvent = { [weak self] event in self?.parts.world.handle(event) }
    parts.world.onFocusMoved = { [weak self] snapshot in
      if self?.parts.overview.isOpen == false { self?.parts.minimap.flash(snapshot) }
    }
    parts.world.onAdopted = { [weak self] snapshot in self?.parts.overview.refresh(with: snapshot) }
    parts.minimap.onSelect = { [weak self] column in self?.focus(column: column) }
    parts.overview.onChoose = { [weak self] column in self?.focus(column: column) }
  }

  var position: StripPosition? { parts.world.position }

  var notice: String? { parts.supervisor.state.failure?.message }

  func report(selected: WindowEngine) -> EngineReport {
    parts.reporter.report(selected: selected)
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
        Self.logger.error("Could not rewrite the engine configuration")
      }
    }
    if !parts.store.preferences.showsMinimap { parts.minimap.hide() }
    applyBindings()
  }

  private func performLocally(_ action: Action) {
    switch (action, status) {
    case (.togglePaused, .running): pause()
    case (.togglePaused, .paused): begin()
    case (.toggleOverview, .running): parts.overview.toggle(with: parts.world.snapshot)
    default: Self.logger.info("Dropped \(action.commandName, privacy: .public): paused")
    }
  }

  private func begin() {
    status = .running
    parts.supervisor.start()
    parts.drag.start()
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
    parts.overview.close()
    parts.minimap.hide()
    parts.events.stop()
    parts.world.clear()
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
      parts.events.stop()
      parts.world.clear()
      status = .paused
      applyBindings()
    case .needsPermission:
      awaitAccessibility()
    case .stopped, .starting, .waitingToRestart:
      break
    }
  }

  private func applyBindings() {
    parts.bindings.apply(
      isRunning: status == .running, perform: { [weak self] action in self?.perform(action) },
      jump: { [weak self] bundle in self?.parts.appShortcuts.jump(to: bundle) })
  }

  private func focus(column: Int) {
    send(PaneruCommand("window", "focus", "\(column + 1)"))
  }

  private func send(_ command: PaneruCommand) {
    Task { await parts.commands.send(command.words) }
  }
}
