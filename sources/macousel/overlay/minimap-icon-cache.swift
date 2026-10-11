import AppKit

final class MinimapIconCache {
  private var icons: [String: NSImage] = [:]

  func icon(for bundleIdentifier: String) -> NSImage {
    if let cached = icons[bundleIdentifier] { return cached }
    let icon = AppIdentity(bundleIdentifier: bundleIdentifier, iconSide: Metrics.Minimap.iconSide)
      .icon
    icons[bundleIdentifier] = icon
    return icon
  }
}
