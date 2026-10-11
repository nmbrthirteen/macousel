import Foundation
import WindowSystem

struct DiagnosticsEnvironment {
  var appVersion: String
  var build: String
  var osVersion: String
  var displays: [Display]

  static func current(bundle: Bundle = .main) -> DiagnosticsEnvironment {
    DiagnosticsEnvironment(
      appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        ?? "development",
      build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
      osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
      displays: Display.all())
  }
}
