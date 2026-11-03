import Foundation
import WindowSystem
import os

final class SystemEngineProcess: EngineProcess {
  let exits: AsyncStream<Int32>
  private let process: Process

  init(process: Process, exits: AsyncStream<Int32>) {
    self.process = process
    self.exits = exits
  }

  var isRunning: Bool { process.isRunning }

  func terminate() {
    process.terminate()
  }

  func kill() {
    Foundation.kill(process.processIdentifier, SIGKILL)
  }
}

final class SystemEngineLauncher: EngineProcessLauncher {
  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  private let log: EngineLog

  init(log: EngineLog) {
    self.log = log
  }

  func launch(_ launch: EngineLaunch) throws -> any EngineProcess {
    for key in ["XDG_STATE_HOME", "XDG_CONFIG_HOME"] {
      guard let path = launch.environment[key] else { continue }
      try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    let process = Process()
    let errors = Pipe()
    process.executableURL = launch.executable
    process.arguments = launch.arguments
    process.environment = launch.environment
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = errors
    let (exits, continuation) = AsyncStream<Int32>.makeStream()
    let log = log
    errors.fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      if data.isEmpty {
        handle.readabilityHandler = nil
      } else {
        log.append(data)
      }
    }
    process.terminationHandler = { finished in
      continuation.yield(finished.terminationStatus)
      continuation.finish()
    }
    try process.run()
    startWatchdog(engine: process.processIdentifier)
    return SystemEngineProcess(process: process, exits: exits)
  }

  private func startWatchdog(engine: pid_t) {
    guard let executable = Bundle.main.executableURL else { return }
    let watchdog = Process()
    watchdog.executableURL = executable
    watchdog.arguments = EngineWatchdog.arguments(
      parent: ProcessInfo.processInfo.processIdentifier, engine: engine)
    watchdog.environment = ChildEnvironment.current()
    watchdog.standardInput = FileHandle.nullDevice
    watchdog.standardOutput = FileHandle.nullDevice
    watchdog.standardError = FileHandle.nullDevice
    do {
      try watchdog.run()
    } catch {
      Self.logger.error("Could not start the engine watchdog: \(error, privacy: .public)")
    }
  }
}
