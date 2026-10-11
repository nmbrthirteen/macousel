import Foundation

struct IsolatedDefaultsUnavailable: Error {}

@MainActor
final class IsolatedDefaults {
  let name: String
  let defaults: UserDefaults

  init() throws {
    let name = FileManager.default.temporaryDirectory
      .appendingPathComponent("macousel-tests-\(UUID().uuidString)").path
    guard let defaults = UserDefaults(suiteName: name) else { throw IsolatedDefaultsUnavailable() }
    self.name = name
    self.defaults = defaults
    try FixtureRegistry.enroll(self)
  }

  func remove() {
    defaults.removePersistentDomain(forName: name)
    defaults.synchronize()
    try? FileManager.default.removeItem(atPath: name + ".plist")
  }
}
