import SwiftUI

struct SettingsFileSection: View {
  @State private var transfer: SettingsFileTransfer

  init(store: PreferencesStore) {
    _transfer = State(initialValue: SettingsFileTransfer(store: store))
  }

  var body: some View {
    SettingsGroup(title: "Settings file") {
      HStack(spacing: Metrics.Spacing.comfortable) {
        Button("Export settings…", action: transfer.exportSettings)
        Button("Import settings…", action: transfer.importSettings)
      }
      if let message = transfer.errorMessage {
        ErrorText(message)
      } else if let message = transfer.statusMessage {
        CaptionText(message)
      }
    }
  }
}
