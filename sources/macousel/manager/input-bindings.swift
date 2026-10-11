import WindowSystem
import os

final class InputBindings {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "shortcuts")

  private let store: PreferencesStore
  private let shortcuts: any ShortcutRegistry
  private let interactions: ManagerInteractions
  private let appShortcuts: AppShortcutLauncher

  init(
    store: PreferencesStore, shortcuts: any ShortcutRegistry, interactions: ManagerInteractions,
    appShortcuts: AppShortcutLauncher
  ) {
    self.store = store
    self.shortcuts = shortcuts
    self.interactions = interactions
    self.appShortcuts = appShortcuts
  }

  func apply(isTiling: Bool, perform: @escaping (Action) -> Void) {
    let requested = bindings(isTiling: isTiling, perform: perform)
    let failures = shortcuts.setBindings(requested)
    let registered = requested.count - failures
    Self.logger.info(
      "registered \(registered, privacy: .public) shortcuts, \(failures, privacy: .public) failed")
    interactions.configure(isTiling: isTiling)
  }

  func release() {
    shortcuts.removeAll()
    interactions.stop()
  }

  private func bindings(isTiling: Bool, perform: @escaping (Action) -> Void) -> [Hotkey:
    () -> Void]
  {
    guard !store.isRecordingShortcut else { return [:] }
    var bindings: [Hotkey: () -> Void] = [:]
    for (action, keys) in store.preferences.shortcuts where isTiling || action == .togglePaused {
      for key in keys {
        bindings[key] = { perform(action) }
      }
    }
    guard isTiling else { return bindings }
    for shortcut in store.preferences.appShortcuts {
      bindings[shortcut.hotkey] = { [appShortcuts] in
        appShortcuts.jump(to: shortcut.bundleIdentifier)
      }
    }
    return bindings
  }
}
