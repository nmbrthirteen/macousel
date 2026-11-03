import WindowSystem
import os

final class InputBindings {
  private static let logger = Logger(subsystem: Log.subsystem, category: "shortcuts")

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
    return store.preferences.hotkeyBindings(
      including: { isTiling || $0 == .togglePaused }, perform: perform,
      jump: isTiling ? { [appShortcuts] in appShortcuts.jump(to: $0) } : nil)
  }
}

extension Preferences {
  func hotkeyBindings(
    including includes: (Action) -> Bool, perform: @escaping (Action) -> Void,
    jump: ((String) -> Void)?
  ) -> [Hotkey: () -> Void] {
    var bindings: [Hotkey: () -> Void] = [:]
    for (action, keys) in shortcuts where includes(action) {
      for key in keys {
        bindings[key] = { perform(action) }
      }
    }
    guard let jump else { return bindings }
    for shortcut in appShortcuts {
      bindings[shortcut.hotkey] = { jump(shortcut.bundleIdentifier) }
    }
    return bindings
  }
}
