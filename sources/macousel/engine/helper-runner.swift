import Foundation

nonisolated struct HelperRunner: Sendable {
  static let standardTimeout = 3.0
  static let killGrace = 1.0

  var timeout = Self.standardTimeout

  // Nothing here blocks a thread: the output arrives through a readability handler and the
  // exit through the termination handler, so a grandchild that keeps the pipe open cannot hang
  // the caller. The timers check isRunning on the Process, which Foundation clears when it
  // reaps the child, so a reused pid is never signalled.
  func run(_ executable: URL, arguments: [String], environment: [String: String]) async
    -> ProcessOutput?
  {
    let timeout = timeout
    return await withCheckedContinuation { continuation in
      let process = Process()
      let pipe = Pipe()
      process.executableURL = executable
      process.arguments = arguments
      process.environment = environment
      process.standardInput = FileHandle.nullDevice
      process.standardOutput = pipe
      process.standardError = FileHandle.nullDevice
      let output = HelperOutput(reading: pipe.fileHandleForReading)
      process.terminationHandler = { finished in
        let data = output.finish()
        continuation.resume(
          returning: ProcessOutput(
            status: finished.terminationStatus, text: String(decoding: data, as: UTF8.self)))
      }
      do {
        try process.run()
      } catch {
        process.terminationHandler = nil
        _ = output.finish()
        continuation.resume(returning: nil)
        return
      }
      let queue = DispatchQueue.global(qos: .utility)
      queue.asyncAfter(deadline: .now() + timeout) {
        guard process.isRunning else { return }
        process.terminate()
        queue.asyncAfter(deadline: .now() + Self.killGrace) {
          guard process.isRunning else { return }
          kill(process.processIdentifier, SIGKILL)
        }
      }
    }
  }
}

private nonisolated final class HelperOutput: @unchecked Sendable {
  private let handle: FileHandle
  private let lock = NSLock()
  private var data = Data()
  private var isFinished = false

  // The descriptor is non-blocking and read only under the lock, so chunks keep their order
  // and the final drain never waits on a writer that has not closed the pipe.
  init(reading handle: FileHandle) {
    self.handle = handle
    let descriptor = handle.fileDescriptor
    _ = fcntl(descriptor, F_SETFL, fcntl(descriptor, F_GETFL) | O_NONBLOCK)
    handle.readabilityHandler = { [weak self] handle in
      guard let self, self.drain() else { return }
      handle.readabilityHandler = nil
    }
  }

  func finish() -> Data {
    lock.lock()
    isFinished = true
    _ = readAvailable()
    let result = data
    lock.unlock()
    handle.readabilityHandler = nil
    return result
  }

  private func drain() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return isFinished || readAvailable()
  }

  private func readAvailable() -> Bool {
    var buffer = [UInt8](repeating: 0, count: 16_384)
    while true {
      let count = read(handle.fileDescriptor, &buffer, buffer.count)
      if count > 0 {
        data.append(contentsOf: buffer[0..<count])
      } else {
        return count == 0
      }
    }
  }
}
