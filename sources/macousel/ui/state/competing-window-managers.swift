import AppKit

enum CompetingWindowManagers {
  private static let bundled: [(name: String, bundleIdentifier: String)] = [
    ("Rectangle", "com.knollsoft.Rectangle"),
    ("Rectangle Pro", "com.knollsoft.Hookshot"),
    ("Magnet", "com.crowdcafe.windowmagnet"),
    ("AeroSpace", "bobko.aerospace"),
    ("Amethyst", "com.amethyst.Amethyst"),
    ("Loop", "com.MrKai77.Loop"),
    ("BetterSnapTool", "com.hegenberg.BetterSnapTool"),
    ("Moom", "com.manytricks.Moom"),
  ]
  private static let yabaiProcessName = "yabai"
  private static let pgrepPath = "/usr/bin/pgrep"

  static func running(includingYabai runsYabai: Bool) -> [String] {
    let identifiers = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    let found = bundled.filter { identifiers.contains($0.bundleIdentifier) }.map(\.name)
    return runsYabai ? found + [yabaiProcessName] : found
  }

  // yabai is a bare process with no bundle, so finding it takes pgrep.
  static func isYabaiRunning() async -> Bool {
    (try? await ProcessRunner.run(pgrepPath, ["-x", yabaiProcessName])) == 0
  }
}
