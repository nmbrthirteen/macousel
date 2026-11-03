import WindowSystem
import os

final class PaneruInputBindings {
  private static let logger = Logger(subsystem: Log.subsystem, category: "shortcuts")

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
    let bindings = store.preferences.hotkeyBindings(
      including: { $0 == .togglePaused || ($0 == .toggleOverview && isRunning) },
      perform: perform, jump: isRunning ? jump : nil)
    let failures = shortcuts.setBindings(bindings)
    if failures > 0 {
      Self.logger.error(
        "\(failures, privacy: .public) of \(bindings.count) shortcuts failed to register")
    }
  }

  func release() {
    shortcuts.removeAll()
  }
}
