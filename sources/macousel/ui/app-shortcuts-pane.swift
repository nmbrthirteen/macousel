import SwiftUI

struct AppShortcutsPane: View {
  @Bindable var store: PreferencesStore
  @State private var runningApps = RunningApps()
  @State private var chooser = ApplicationChooser()
  @State private var draft: String?

  var body: some View {
    SettingsForm {
      SettingsGroup(
        title: "Apps", footer: "Press the key again to cycle through the app's windows."
      ) {
        if store.preferences.appShortcuts.isEmpty && draft == nil {
          CaptionText("No app shortcuts yet. If an app is not running, its key opens it.")
        }
        ForEach(store.preferences.appShortcuts) { shortcut in
          AppShortcutRow(
            bundleIdentifier: shortcut.bundleIdentifier, hotkey: shortcut.hotkey, store: store,
            onRemove: { remove(shortcut) })
        }
        if let draft {
          AppShortcutRow(
            bundleIdentifier: draft, hotkey: nil, store: store, startsRecording: true,
            onStop: { self.draft = nil }, onRemove: { self.draft = nil }
          )
          .id(draft)
        }
      }

      Section {
        Menu("Add an app") {
          ForEach(addableApps) { app in
            Button { draft = app.id } label: { AppLabel(identity: app) }
          }
          Divider()
          Button("Choose an app…", action: chooseApp)
        }
        if let message = chooser.errorMessage {
          ErrorText(message)
        }
      }
    }
    .onAppear(perform: runningApps.start)
    .onDisappear(perform: runningApps.stop)
  }

  private var listedIdentifiers: Set<String> {
    Set(store.preferences.appShortcuts.map(\.bundleIdentifier))
  }

  private var addableApps: [AppIdentity] {
    runningApps.excluding(listedIdentifiers)
  }

  private func chooseApp() {
    if let identifier = chooser.choose(excluding: listedIdentifiers) { draft = identifier }
  }

  private func remove(_ shortcut: AppShortcut) {
    store.preferences.appShortcuts.removeAll { $0.id == shortcut.id }
  }
}
