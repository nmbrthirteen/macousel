import AppKit
import Observation

final class DockPolicy {
  private let store: PreferencesStore

  // Settings acts as a regular app while it is open, so it shows in the Dock and in ⌘Tab.
  var hasOpenWindow = false {
    didSet { apply() }
  }

  init(store: PreferencesStore) {
    self.store = store
  }

  func start() {
    _ = withObservationTracking {
      store.preferences.showsInDock
    } onChange: { [weak self] in
      Task { @MainActor in self?.start() }
    }
    apply()
  }

  private func apply() {
    let showsInDock = store.preferences.showsInDock || hasOpenWindow
    let policy: NSApplication.ActivationPolicy = showsInDock ? .regular : .accessory
    guard NSApp.activationPolicy() != policy else { return }
    NSApp.setActivationPolicy(policy)
    if showsInDock { NSApp.activate() }
  }
}
