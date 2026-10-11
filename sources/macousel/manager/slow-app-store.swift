import Foundation

struct SlowAppStore {
  static let capacity = 50
  private static let key = "slowApps"

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func load() -> Set<String> {
    Set(stored)
  }

  func record(_ bundleIdentifier: String, isSlow: Bool) {
    var identifiers = stored.filter { $0 != bundleIdentifier }
    if isSlow { identifiers.append(bundleIdentifier) }
    defaults.set(Array(identifiers.suffix(Self.capacity)), forKey: Self.key)
  }

  private var stored: [String] {
    defaults.stringArray(forKey: Self.key) ?? []
  }
}
