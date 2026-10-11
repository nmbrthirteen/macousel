import Foundation
import os

final class SystemCrashRecovery: CrashRecovery {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "crash-recovery")
  private static let recoveryFlag = "--recover-windows"
  private static let watchScript =
    "while kill -0 \"$1\" 2>/dev/null; do sleep 1; done; /usr/bin/open \"$2\" --args \"$3\""

  private var watcher: Process?

  var isRecoveringFromCrash: Bool {
    ProcessInfo.processInfo.arguments.contains(Self.recoveryFlag)
  }

  func arm() {
    let bundle = Bundle.main.bundleURL
    guard watcher == nil, bundle.pathExtension == "app" else { return }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = [
      "-c", Self.watchScript, "sh",
      String(ProcessInfo.processInfo.processIdentifier), bundle.path, Self.recoveryFlag,
    ]
    do {
      try process.run()
      watcher = process
    } catch {
      Self.logger.error("Could not start the crash watchdog: \(error.localizedDescription)")
    }
  }

  func disarm() {
    watcher?.terminate()
    watcher = nil
  }
}
