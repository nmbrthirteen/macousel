import Foundation
import os

final class SystemCrashRecovery: CrashRecovery {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "crash-recovery")
  private static let recoveryFlag = "--recover-windows"
  private static let cleanExitMarker = "x"
  private static let watchScript =
    "marker=$(dd bs=1 count=1 2>/dev/null); [ \"$marker\" = \"$1\" ] && exit 0; /usr/bin/open \"$2\" --args \"$3\""

  private var watcher: Process?
  private var lifeline: FileHandle?

  var isRecoveringFromCrash: Bool {
    ProcessInfo.processInfo.arguments.contains(Self.recoveryFlag)
  }

  func arm() {
    let bundle = Bundle.main.bundleURL
    guard watcher == nil, bundle.pathExtension == "app" else { return }
    let pipe = Pipe()
    let writer = pipe.fileHandleForWriting
    _ = fcntl(writer.fileDescriptor, F_SETFD, FD_CLOEXEC)
    _ = fcntl(writer.fileDescriptor, F_SETNOSIGPIPE, 1)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = [
      "-c", Self.watchScript, "sh", Self.cleanExitMarker, bundle.path, Self.recoveryFlag,
    ]
    process.standardInput = pipe.fileHandleForReading
    do {
      try process.run()
      try? pipe.fileHandleForReading.close()
      watcher = process
      lifeline = writer
    } catch {
      Self.logger.error("Could not start the crash watchdog: \(error.localizedDescription)")
    }
  }

  func disarm() {
    if let lifeline {
      try? lifeline.write(contentsOf: Data(Self.cleanExitMarker.utf8))
      try? lifeline.close()
    }
    lifeline = nil
    watcher = nil
  }
}
