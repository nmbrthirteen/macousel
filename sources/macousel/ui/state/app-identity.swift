import AppKit

struct AppIdentity: Identifiable {
  let id: String
  let name: String
  let icon: NSImage

  init(id: String, name: String, icon: NSImage, iconSide: Double = Metrics.Size.appIcon) {
    self.id = id
    self.name = name
    self.icon = icon.resized(toSide: iconSide)
  }

  init(bundleIdentifier: String, iconSide: Double = Metrics.Size.appIcon) {
    let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    self.init(
      id: bundleIdentifier,
      name: url.map { FileManager.default.displayName(atPath: $0.path) } ?? bundleIdentifier,
      icon: url.map { NSWorkspace.shared.icon(forFile: $0.path) } ?? NSImage(),
      iconSide: iconSide
    )
  }

  private struct CacheKey: Hashable {
    let bundleIdentifier: String
    let iconSide: Double
  }

  private static var cache: [CacheKey: AppIdentity] = [:]

  // Rows rebuild on every settings change, and each lookup asks Launch Services and
  // resizes an icon.
  static func cached(bundleIdentifier: String, iconSide: Double = Metrics.Size.appIcon)
    -> AppIdentity
  {
    let key = CacheKey(bundleIdentifier: bundleIdentifier, iconSide: iconSide)
    if let hit = cache[key] { return hit }
    let identity = AppIdentity(bundleIdentifier: bundleIdentifier, iconSide: iconSide)
    cache[key] = identity
    return identity
  }

  init?(running application: NSRunningApplication) {
    guard let identifier = application.bundleIdentifier, let name = application.localizedName
    else { return nil }
    self.init(id: identifier, name: name, icon: application.icon ?? NSImage())
  }
}
