import AppKit

final class AppIconCache {
  private static let entryLimit = 64

  private let iconSide: Double
  private var icons = LRUCache<String, NSImage>(limit: entryLimit)

  init(iconSide: Double) {
    self.iconSide = iconSide
  }

  func icon(for bundleIdentifier: String) -> NSImage {
    icons.value(for: bundleIdentifier) {
      AppIdentity(bundleIdentifier: bundleIdentifier, iconSide: iconSide).icon
    }
  }
}
