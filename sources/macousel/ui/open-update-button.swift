import SwiftUI

struct OpenUpdateButton: View {
  let version: AppVersion
  @Environment(\.openWindow) private var openWindow
  @AppStorage(SettingsSection.storageKey) private var selection = SettingsSection.general

  var body: some View {
    Button("Update to \(version.description)…") {
      selection = .about
      openWindow(id: SettingsWindow.id)
      NSApp.activate()
    }
  }
}
