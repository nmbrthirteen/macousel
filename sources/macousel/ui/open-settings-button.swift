import SwiftUI

struct OpenSettingsButton: View {
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Button("Settings…") {
      openWindow(id: SettingsWindow.id)
      NSApp.activate()
    }
    .keyboardShortcut(",")
  }
}
