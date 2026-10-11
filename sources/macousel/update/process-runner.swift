import Foundation

enum ProcessRunner {
  static func run(_ executable: String, _ arguments: [String]) async throws -> Int32 {
    try await withCheckedThrowingContinuation { continuation in
      let process = Process()
      process.executableURL = URL(fileURLWithPath: executable)
      process.arguments = arguments
      process.standardOutput = FileHandle.nullDevice
      process.standardError = FileHandle.nullDevice
      process.terminationHandler = { finished in
        continuation.resume(returning: finished.terminationStatus)
      }
      do {
        try process.run()
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  static func capture(_ executable: String, _ arguments: [String]) async throws -> ProcessOutput {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .utility).async {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        process.qualityOfService = .utility
        do {
          try process.run()
        } catch {
          continuation.resume(throwing: error)
          return
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        continuation.resume(
          returning: ProcessOutput(
            status: process.terminationStatus, text: String(decoding: data, as: UTF8.self)))
      }
    }
  }
}
