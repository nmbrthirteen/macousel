import Foundation
import Observation

@Observable
final class SettingsFileTransfer {
  private(set) var errorMessage: String?
  private(set) var statusMessage: String?

  @ObservationIgnored private let store: PreferencesStore
  @ObservationIgnored private let panels: SettingsFilePanels

  init(store: PreferencesStore, panels: SettingsFilePanels = .system) {
    self.store = store
    self.panels = panels
  }

  func exportSettings() {
    guard let file = panels.exportDestination() else { return }
    do {
      try SettingsFile.encode(store.preferences).write(to: file, options: .atomic)
      succeed("Exported settings to \(file.lastPathComponent).")
    } catch {
      fail(
        "Could not export settings: \(error.localizedDescription) Choose another location and try again."
      )
    }
  }

  func importSettings() {
    guard let file = panels.importSource() else { return }
    do {
      let data = try Data(contentsOf: file)
      store.preferences = try SettingsFile.decode(data, keepingOnboardingFrom: store.preferences)
      succeed("Imported settings from \(file.lastPathComponent).")
    } catch {
      fail("Could not import settings: \(error.localizedDescription) Nothing was changed.")
    }
  }

  private func succeed(_ message: String) {
    errorMessage = nil
    statusMessage = message
  }

  private func fail(_ message: String) {
    statusMessage = nil
    errorMessage = message
  }
}
