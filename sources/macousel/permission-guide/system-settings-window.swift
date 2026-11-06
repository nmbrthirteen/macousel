import AppKit

// Finds the System Settings window so the helper panel can sit beside it. Window bounds need no
// Screen Recording permission, only window titles do.
enum SystemSettingsWindow {
  static let bundleIdentifier = "com.apple.systempreferences"

  static var frame: CGRect? {
    guard
      let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        .first,
      let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], 0)
        as? [[String: Any]]
    else { return nil }
    let pid = app.processIdentifier
    return
      list
      .filter { ($0[kCGWindowOwnerPID as String] as? pid_t) == pid }
      .filter { ($0[kCGWindowLayer as String] as? Int) == 0 }
      .compactMap { info -> CGRect? in
        guard let bounds = info[kCGWindowBounds as String] as? NSDictionary else { return nil }
        return CGRect(dictionaryRepresentation: bounds)
      }
      .max { $0.width * $0.height < $1.width * $1.height }?
      .axToCocoa
  }
}
