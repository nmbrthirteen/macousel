import SwiftUI

struct SettingsCommands: Commands {
  var body: some Commands {
    CommandGroup(replacing: .appSettings) {
      OpenSettingsButton()
    }
  }
}
