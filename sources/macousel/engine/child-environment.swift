import Foundation

// Helpers inherit Macousel's environment. A DYLD_ variable there would load foreign code into
// processes that hold the Accessibility grant, so it never passes through.
nonisolated enum ChildEnvironment {
  static func current(adding overrides: [String: String] = [:]) -> [String: String] {
    sanitized(ProcessInfo.processInfo.environment).merging(overrides) { _, override in override }
  }

  static func sanitized(_ base: [String: String]) -> [String: String] {
    base.filter { !$0.key.hasPrefix("DYLD_") }
  }
}
