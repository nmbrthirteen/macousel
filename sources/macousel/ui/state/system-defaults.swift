import Foundation

struct SystemDefaults {
  let domain: String

  func bool(forKey key: String) -> Bool? {
    UserDefaults(suiteName: domain)?.object(forKey: key) as? Bool
  }
}

extension SystemDefaults {
  static let spaces = SystemDefaults(domain: "com.apple.spaces")
  static let dock = SystemDefaults(domain: "com.apple.dock")
  static let windowManager = SystemDefaults(domain: "com.apple.WindowManager")
}
