import SwiftUI

struct AppShortcutsPane: View {
  @Bindable var store: PreferencesStore
  @State private var runningApps = RunningApps()
  @State private var chooser = ApplicationChooser()
  @State private var draft: String?

  var body: some View {
    SettingsForm {
      if store.preferences.appShortcuts.isEmpty && draft == nil {
        Section {
          ContentUnavailableView(
            "No app shortcuts", systemImage: "arrow.up.forward.app",
            description: Text(
              "Add an app to jump to it with one key. If it is not running, the key opens it."))
        }
      } else {
        Section {
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
        } header: {
          Text("Apps")
        } footer: {
          CaptionText("Press the key again to cycle through the app's windows.")
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
