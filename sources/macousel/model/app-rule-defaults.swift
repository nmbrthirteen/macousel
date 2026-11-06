extension AppRule {
  private static let floatingBundleIdentifiers = [
    "com.apple.systempreferences",
    "com.apple.calculator",
    "com.apple.ActivityMonitor",
    "com.apple.Stickies",
    "com.apple.DigitalColorMeter",
    "com.apple.archiveutility",
    "com.apple.FaceTime",
    "com.apple.PhotoBooth",
    "com.apple.ScreenContinuity",
    "com.apple.SystemProfiler",
    "com.apple.quicklook.QuickLookUIService",
  ]

  static let defaults: [AppRule] = floatingBundleIdentifiers.map {
    AppRule(bundleIdentifier: $0, behavior: .float)
  }
}
