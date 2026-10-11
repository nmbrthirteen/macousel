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

  static func running() -> [String] {
    let identifiers = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    let found = bundled.filter { identifiers.contains($0.bundleIdentifier) }.map(\.name)
    return isProcessRunning(named: yabaiProcessName) ? found + [yabaiProcessName] : found
  }

  private static func isProcessRunning(named name: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: pgrepPath)
    process.arguments = ["-x", name]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
    } catch {
      return false
    }
    process.waitUntilExit()
    return process.terminationStatus == 0
  }
}
