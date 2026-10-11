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
  private let builtIn: BuiltInEngine
  private let paneru: PaneruEngine

  convenience init(store: PreferencesStore) {
    let ports = ManagerPorts.system()
    self.init(
      store: store, ports: ports, defaults: .standard,
      paneru: .system(
        store: store, environment: ports.environment, shortcuts: ports.shortcuts))
  }

  init(
    store: PreferencesStore, ports: ManagerPorts, defaults: UserDefaults,
    polling: AccessibilityMonitor.Intervals = .standard, paneru: PaneruEngine? = nil
  ) {
    self.store = store
    selected = store.preferences.engine
    builtIn = BuiltInEngine(store: store, ports: ports, defaults: defaults, polling: polling)
    self.paneru =
      paneru
      ?? .system(
        store: store, environment: ports.environment, shortcuts: ports.shortcuts)
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
    store.onChange = { [weak self] in self?.preferencesChanged() }
    selected = store.preferences.engine
    active.start()
  }

  func perform(_ action: Action) {
    active.perform(action)
  }

  func shutdown() {
    active.shutdown()
  }

  func engineReport() -> EngineReport {
    paneru.report(selected: selected)
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
