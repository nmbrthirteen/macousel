import AppKit
import UniformTypeIdentifiers

struct SettingsFilePanels {
  var exportDestination: () -> URL?
  var importSource: () -> URL?

  static let system = SettingsFilePanels(
    exportDestination: {
      let panel = NSSavePanel()
      panel.nameFieldStringValue = SettingsFile.defaultFileName
      panel.allowedContentTypes = [.json]
      return panel.runModal() == .OK ? panel.url : nil
    },
    importSource: {
      let panel = NSOpenPanel()
      panel.allowedContentTypes = [.json]
      panel.allowsMultipleSelection = false
      return panel.runModal() == .OK ? panel.url : nil
    })
}
