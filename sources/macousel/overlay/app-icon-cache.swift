import AppKit

final class AppIconCache {
  private let iconSide: Double
  private var icons: [String: NSImage] = [:]

  init(iconSide: Double) {
    self.iconSide = iconSide
  }

  func icon(for bundleIdentifier: String) -> NSImage {
    if let cached = icons[bundleIdentifier] { return cached }
    let icon = AppIdentity(bundleIdentifier: bundleIdentifier, iconSide: iconSide).icon
    icons[bundleIdentifier] = icon
    return icon
  }
}
