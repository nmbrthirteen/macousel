import SwiftUI

struct ShortcutsPane: View {
  @Bindable var store: PreferencesStore
  @State private var filter = ShortcutsFilter()
  @State private var confirmsRestore = false

  var body: some View {
    SettingsForm {
      Section {
        SearchField(label: "Filter shortcuts", text: $filter.query)
      }

      if !filter.isFiltering {
        SettingsGroup(title: "Base keys") {
          Picker(selection: baseBinding) {
            ForEach(ShortcutBase.allCases, id: \.self) { base in
              Text("\(base.title) (\(base.symbol))").tag(base)
            }
          } label: {
            RowLabel(title: "Base keys", detail: baseKeysDetail)
          }
        }
      }

      if filter.entries.isEmpty {
        ContentUnavailableView.search(text: filter.query)
      }

      ForEach(filter.entries) { entry in
        SettingsGroup(title: entry.group.title) {
          ForEach(entry.actions, id: \.self) { action in
            ShortcutRow(action: action, store: store)
          }
        }
      }

      if !filter.isFiltering {
        Section {
          Button("Restore default shortcuts") { confirmsRestore = true }
        }
      }
    }
    .confirmationDialog("Restore default shortcuts?", isPresented: $confirmsRestore) {
      Button("Restore defaults", role: .destructive, action: store.resetShortcuts)
    } message: {
      Text("This replaces every shortcut you changed.")
    }
  }

  private var baseKeysDetail: String {
    let note = "Shortcuts you changed keep their keys."
    guard let warning = store.preferences.shortcutBase.warning else { return note }
    return "\(note) \(warning)"
  }

  private var baseBinding: Binding<ShortcutBase> {
    Binding(get: { store.preferences.shortcutBase }, set: { store.setShortcutBase($0) })
  }
}
