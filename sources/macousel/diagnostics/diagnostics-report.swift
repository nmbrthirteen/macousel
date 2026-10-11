import CoreGraphics
import WindowSystem

struct DiagnosticsReport {
  let environment: DiagnosticsEnvironment
  let preferencesJSON: String
  let crashReports: [String]
  let log: String
  var engine: EngineReport?

  var text: String {
    [
      "Macousel diagnostics",
      "App version: \(environment.appVersion) (build \(environment.build))",
      "macOS: \(environment.osVersion)",
      section("Displays", lines: environment.displays.map(describe)),
      section("Preferences", lines: [preferencesJSON]),
      section("Crash reports", lines: crashReports.isEmpty ? ["None"] : crashReports),
      section("Log, last 15 minutes", lines: [log]),
    ].joined(separator: "\n\n") + engineText + "\n"
  }

  private var engineText: String {
    engine.map { "\n\n" + $0.text } ?? ""
  }

  private func section(_ title: String, lines: [String]) -> String {
    ([title] + lines).joined(separator: "\n")
  }

  private func describe(_ display: Display) -> String {
    "\(display.name): frame \(describe(display.frame)), visible \(describe(display.visibleFrame))"
  }

  private func describe(_ rect: CGRect) -> String {
    "x \(rect.minX) y \(rect.minY) width \(rect.width) height \(rect.height)"
  }
}
