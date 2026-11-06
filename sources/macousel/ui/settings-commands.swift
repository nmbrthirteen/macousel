import SwiftUI

struct SettingsCommands: Commands {
  let showSettings: () -> Void

  var body: some Commands {
    CommandGroup(replacing: .appSettings) {
      Button("Settings…", action: showSettings)
        .keyboardShortcut(",")
    }
  }
}
