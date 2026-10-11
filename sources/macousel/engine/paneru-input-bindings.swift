import WindowSystem

final class PaneruInputBindings {
  private let store: PreferencesStore
  private let shortcuts: any ShortcutRegistry

  init(store: PreferencesStore, shortcuts: any ShortcutRegistry) {
    self.store = store
    self.shortcuts = shortcuts
  }

  func apply(
    isRunning: Bool, perform: @escaping (Action) -> Void,
    jump: @escaping (String) -> Void
  ) {
    guard !store.isRecordingShortcut else {
      shortcuts.removeAll()
      return
    }
    var bindings: [Hotkey: () -> Void] = [:]
    for action in [Action.togglePaused, .toggleOverview] where isRunning || action == .togglePaused {
      for key in store.preferences.shortcuts[action] ?? [] {
        bindings[key] = { perform(action) }
      }
    }
    if isRunning {
      for shortcut in store.preferences.appShortcuts {
        bindings[shortcut.hotkey] = { jump(shortcut.bundleIdentifier) }
      }
    }
    _ = shortcuts.setBindings(bindings)
  }

  func release() {
    shortcuts.removeAll()
  }
}
