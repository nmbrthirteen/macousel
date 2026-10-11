import SwiftUI

struct ShortcutsPane: View {
  @Bindable var store: PreferencesStore

  var body: some View {
    SettingsForm {
      ForEach(Action.Group.allCases, id: \.self) { group in
        Section(group.title) {
          ForEach(Action.allCases.filter { $0.group == group }, id: \.self) { action in
            ShortcutRow(action: action, store: store)
          }
        }
      }

      Section {
        Button("Restore defaults", action: store.resetShortcuts)
      }
    }
  }
}
