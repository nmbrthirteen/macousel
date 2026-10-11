import Foundation

struct AppRelauncher {
  private static let script =
    "while kill -0 \"$1\" 2>/dev/null; do sleep 0.2; done; /usr/bin/open \"$2\""

  func start(
    opening bundleURL: URL, afterExitOf processID: Int32 = ProcessInfo.processInfo.processIdentifier
  ) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = ["-c", Self.script, "sh", String(processID), bundleURL.path]
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
    } catch {
      throw UpdateInstallError.relaunchFailed
    }
  }
}
