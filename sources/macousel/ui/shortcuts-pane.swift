import SwiftUI

struct ShortcutsPane: View {
  @Bindable var store: PreferencesStore
  @State private var filter = ShortcutsFilter()

  var body: some View {
    SettingsForm {
      Section {
        SearchField(label: "Filter shortcuts", text: $filter.query)
      }

      if filter.entries.isEmpty {
        ContentUnavailableView.search(text: filter.query)
      }

      ForEach(filter.entries) { entry in
        SettingsGroup(title: entry.section.title) {
          ForEach(entry.actions, id: \.self) { action in
            ShortcutRow(action: action, store: store)
          }
        }
      }

      if !filter.isFiltering {
        Section {
          Button("Restore default shortcuts", action: store.resetShortcuts)
        }
      }
    }
  }
}
