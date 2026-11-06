import Foundation
import Observation
import WindowSystem

@Observable
final class WindowManager {
  enum Status: Sendable {
    case needsPermission, running, paused
  }

  private(set) var selected: WindowEngine

  private let store: PreferencesStore
  private let makeBuiltIn: () -> BuiltInEngine
  private let makePaneru: () -> PaneruEngine
  private let clock: any AnimationClock
  private let settleDelay: Duration
  private var pendingApply = 0
  private var wasRecordingShortcut = false

  // The engine nobody selected is built on first use, so it costs no memory until then.
  @ObservationIgnored private lazy var builtIn = makeBuiltIn()
  @ObservationIgnored private lazy var paneru = makePaneru()

  convenience init(store: PreferencesStore) {
    self.init(store: store, ports: ManagerPorts.system(), defaults: .standard)
  }

  init(
    store: PreferencesStore, ports: ManagerPorts, defaults: UserDefaults,
    paneru: PaneruEngine? = nil, settleDelay: Duration = .milliseconds(150)
  ) {
    self.store = store
    clock = ports.clock
    self.settleDelay = settleDelay
    selected = store.preferences.engine
    makeBuiltIn = { BuiltInEngine(store: store, ports: ports, defaults: defaults) }
    makePaneru = {
      paneru
        ?? .system(
          store: store, environment: ports.environment, shortcuts: ports.shortcuts)
    }
  }

  var status: Status { active.status }
  var displays: [Display] { active.displays }
  var position: StripPosition? { active.position }
  var notice: String? { active.notice }

  private var active: any ManagementEngine {
    switch selected {
    case .paneru: paneru
    case .builtIn: builtIn
    }
  }

  func start() {
    store.onChange = { [weak self] in self?.preferencesDidChange() }
    selected = store.preferences.engine
    active.start()
  }

  func perform(_ action: Action) {
    active.perform(action)
  }

  func shutdown() {
    pendingApply += 1
    active.shutdown()
  }

  func engineReport() async -> EngineReport {
    await paneru.report(selected: selected)
  }

  // A slider drag changes preferences every step. The engines rewrite configuration and
  // re-register input on each apply, so only the value after the pause is applied.
  private func preferencesDidChange() {
    let isRecording = store.isRecordingShortcut
    let isImmediate =
      isRecording != wasRecordingShortcut || store.preferences.engine != selected
      || settleDelay <= .zero
    wasRecordingShortcut = isRecording
    pendingApply += 1
    guard !isImmediate else {
      preferencesChanged()
      return
    }
    let ticket = pendingApply
    clock.schedule(after: settleDelay) { [weak self] in
      guard let self, pendingApply == ticket else { return }
      preferencesChanged()
    }
  }

  private func preferencesChanged() {
    guard store.preferences.engine == selected else {
      switchEngine()
      return
    }
    active.preferencesChanged()
  }

  private func switchEngine() {
    active.shutdown()
    selected = store.preferences.engine
    active.start()
  }
}
