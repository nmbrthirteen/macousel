import StripCore

final class RecentAppWindows {
  private let source: any WindowSource
  private var windows: [String: WindowID] = [:]

  init(source: any WindowSource) {
    self.source = source
  }

  func note(_ window: WindowID) {
    guard let bundleIdentifier = source.window(window.rawValue)?.bundleIdentifier else { return }
    windows[bundleIdentifier] = window
  }

  func window(for bundleIdentifier: String) -> WindowID? {
    windows[bundleIdentifier]
  }
}
