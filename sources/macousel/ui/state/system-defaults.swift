import Foundation

struct SystemDefaults {
  let defaults: UserDefaults?

  init(defaults: UserDefaults?) {
    self.defaults = defaults
  }

  init(domain: String) {
    self.init(defaults: UserDefaults(suiteName: domain))
  }

  func bool(forKey key: String) -> Bool? {
    defaults?.object(forKey: key) as? Bool
  }

  func int(forKey key: String) -> Int? {
    defaults?.object(forKey: key) as? Int
  }
}

extension SystemDefaults {
  static let spaces = SystemDefaults(domain: "com.apple.spaces")
  static let dock = SystemDefaults(domain: "com.apple.dock")
  static let windowManager = SystemDefaults(domain: "com.apple.WindowManager")
  static let builtInTrackpad = SystemDefaults(domain: "com.apple.AppleMultitouchTrackpad")
  static let bluetoothTrackpad = SystemDefaults(
    domain: "com.apple.driver.AppleBluetoothMultitouch.trackpad")
}
