import Foundation

nonisolated struct HelperRunner: Sendable {
  static let standardTimeout = 3.0

  var timeout = Self.standardTimeout

  func run(_ executable: URL, arguments: [String], environment: [String: String]) async
    -> ProcessOutput?
  {
    let timeout = timeout
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .utility).async {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
          try process.run()
        } catch {
          continuation.resume(returning: nil)
          return
        }
        let identifier = process.processIdentifier
        let watchdog = DispatchWorkItem { kill(identifier, SIGTERM) }
        DispatchQueue.global(qos: .utility).asyncAfter(
          deadline: .now() + timeout, execute: watchdog)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        watchdog.cancel()
        continuation.resume(
          returning: ProcessOutput(
            status: process.terminationStatus, text: String(decoding: data, as: UTF8.self)))
      }
    }
  }
}
