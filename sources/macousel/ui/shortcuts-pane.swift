import SwiftUI

struct ShortcutsPane: View {
  @Bindable var store: PreferencesStore
  @State private var filter = ShortcutsFilter()

  var body: some View {
    SettingsForm {
      Section {
        SearchField(label: "Filter shortcuts", text: $filter.query)
      }

      if !filter.isFiltering {
        SettingsGroup(title: "Base keys") {
          CaptionedRow(caption: "Shortcuts you changed keep their keys.") {
            Picker("Base keys", selection: baseBinding) {
              ForEach(ShortcutBase.allCases, id: \.self) { base in
                Text("\(base.title) (\(base.symbol))").tag(base)
              }
            }
          }
          if let warning = store.preferences.shortcutBase.warning {
            CaptionText(warning)
          }
        }
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

  private var baseBinding: Binding<ShortcutBase> {
    Binding(get: { store.preferences.shortcutBase }, set: { store.setShortcutBase($0) })
  }
}
