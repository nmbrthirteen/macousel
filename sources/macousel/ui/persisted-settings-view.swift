import SwiftUI

struct PersistedSettingsView: View {
  let store: PreferencesStore
  let manager: WindowManager
  let updater: Updater
  let onShowWelcome: () -> Void
  @State private var diagnostics: DiagnosticsAction
  @AppStorage(SettingsSection.storageKey) private var selection = SettingsSection.general

  init(
    store: PreferencesStore, manager: WindowManager, updater: Updater,
    diagnostics: DiagnosticsAction? = nil, onShowWelcome: @escaping () -> Void
  ) {
    self.store = store
    self.manager = manager
    self.updater = updater
    self.onShowWelcome = onShowWelcome
    _diagnostics = State(initialValue: diagnostics ?? DiagnosticsAction(store: store))
  }

  var body: some View {
    SettingsView(
      store: store, manager: manager, updater: updater, diagnostics: diagnostics,
      onShowWelcome: onShowWelcome, selection: $selection)
  }
}
