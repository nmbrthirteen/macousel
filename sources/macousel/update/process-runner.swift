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
}
