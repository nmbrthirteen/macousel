import Foundation

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
    return SystemEngineProcess(process: process, exits: exits)
  }
}
