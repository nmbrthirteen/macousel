import AppKit
import StripCore

@Observable
final class OverviewModel {
  var snapshot = OverviewSnapshot.empty
  @ObservationIgnored var onSelect: (WindowID) -> Void = { _ in }
  @ObservationIgnored var onDismiss: () -> Void = {}
  @ObservationIgnored private var icons: [String: NSImage] = [:]

  func icon(for bundleIdentifier: String?) -> NSImage? {
    guard let bundleIdentifier else { return nil }
    if let cached = icons[bundleIdentifier] { return cached }
    let icon = AppIdentity(bundleIdentifier: bundleIdentifier, iconSide: Metrics.Overview.iconSide)
      .icon
    icons[bundleIdentifier] = icon
    return icon
  }
}
