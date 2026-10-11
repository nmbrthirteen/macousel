import SwiftUI

struct PersistedSettingsView: View {
  let store: PreferencesStore
  let manager: WindowManager
  let onShowWelcome: () -> Void
  @AppStorage("selectedSettingsSection") private var selection = SettingsSection.general

  var body: some View {
    SettingsView(store: store, manager: manager, onShowWelcome: onShowWelcome, selection: $selection)
  }
}
