import AppKit

struct AppIdentity: Identifiable {
  let id: String
  let name: String
  let icon: NSImage

  init(id: String, name: String, icon: NSImage) {
    self.id = id
    self.name = name
    self.icon = icon.resized(toSide: Metrics.Size.appIcon)
  }

  init(bundleIdentifier: String) {
    let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    self.init(
      id: bundleIdentifier,
      name: url.map { FileManager.default.displayName(atPath: $0.path) } ?? bundleIdentifier,
      icon: url.map { NSWorkspace.shared.icon(forFile: $0.path) } ?? NSImage()
    )
  }

  init?(running application: NSRunningApplication) {
    guard let identifier = application.bundleIdentifier, let name = application.localizedName
    else { return nil }
    self.init(id: identifier, name: name, icon: application.icon ?? NSImage())
  }
}
