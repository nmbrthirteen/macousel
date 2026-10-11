import SwiftUI

struct PersistedSettingsView: View {
  let store: PreferencesStore
  let manager: WindowManager
  let updater: Updater
  let onShowWelcome: () -> Void
  @AppStorage(SettingsSection.storageKey) private var selection = SettingsSection.general

  var body: some View {
    SettingsView(
      store: store, manager: manager, updater: updater, onShowWelcome: onShowWelcome,
      selection: $selection)
  }
}
