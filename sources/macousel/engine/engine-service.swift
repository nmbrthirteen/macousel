enum EngineService {
  static let variable = "PANERU_MACH_SERVICE"
  static let standalone = "com.github.karinushka.paneru"
  static let suffix = ".engine"

  static func privateName(bundleIdentifier: String?) -> String {
    (bundleIdentifier ?? "dev.macousel.app") + suffix
  }
}
