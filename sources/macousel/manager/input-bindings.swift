import WindowSystem

final class InputBindings {
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
    shortcuts.setBindings(bindings(isTiling: isTiling, perform: perform))
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
