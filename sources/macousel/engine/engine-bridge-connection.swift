import Foundation
import WindowSystem
import os

// One long-lived engine-bridge child answers snapshots and commands over its stdin and stdout
// and streams engine events on the same stdout, so no request spawns a process.
final class EngineBridgeConnection {
  static let maximumFailures = 3

  enum Outcome: Equatable {
    // Unavailable means the caller should spawn a helper instead. Failed means the bridge took
    // the request and lost it, so retrying could repeat a command.
    case unavailable, failed
    case answered(EngineBridgeAnswer)
  }

  enum Signal: Equatable {
    case answered
    case event(String)
  }

  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  private struct Child {
    var process: Process
    var input: FileHandle
  }

  private let service: String
  private let timeout: Duration
  private let sleep: (Duration) async throws -> Void
  private let locate: () -> URL?
  private var child: Child?
  private var nextID = 0
  private var pending: [Int: CheckedContinuation<Outcome, Never>] = [:]
  private var deadlines: [Int: Task<Void, Never>] = [:]
  private var listener: AsyncStream<Signal>.Continuation?
  private var failures = 0
  private var loggedFallback = false

  init(
    service: String, timeout: Duration = .seconds(HelperRunner.standardTimeout),
    sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
    locate: @escaping () -> URL?
  ) {
    self.service = service
    self.timeout = timeout
    self.sleep = sleep
    self.locate = locate
  }

  func ask(_ request: EngineBridgeRequest) async -> Outcome {
    guard let running = running() else { return .unavailable }
    nextID += 1
    let id = nextID
    let line: Data
    do {
      line = try request.line(id: id)
    } catch {
      Self.logger.error("Could not encode an engine bridge request: \(error, privacy: .public)")
      return .failed
    }
    return await withCheckedContinuation { continuation in
      pending[id] = continuation
      do {
        try running.input.write(contentsOf: line)
      } catch {
        Self.logger.error("The engine bridge stopped reading: \(error, privacy: .public)")
        discard(failing: true)
        return
      }
      deadlines[id] = Task {
        guard (try? await sleep(timeout)) != nil else { return }
        expire(id)
      }
    }
  }

  // The stream ends when the child does, so the caller can wait and ask again.
  func signals() -> AsyncStream<Signal>? {
    guard running() != nil else { return nil }
    listener?.finish()
    let (stream, continuation) = AsyncStream<Signal>.makeStream()
    listener = continuation
    return stream
  }

  // Ends this engine run's child. The next request starts a fresh one and gets a fresh
  // allowance of failures.
  func close() {
    discard(failing: false)
    failures = 0
  }

  private func running() -> Child? {
    if let child { return child }
    guard failures < Self.maximumFailures, let executable = locate() else {
      if !loggedFallback {
        loggedFallback = true
        Self.logger.error("The engine bridge is missing or keeps failing, spawning helpers instead")
      }
      return nil
    }
    let process = Process()
    let input = Pipe()
    let output = Pipe()
    process.executableURL = executable
    process.arguments = ["serve"]
    process.environment = ChildEnvironment.current(adding: [EngineService.variable: service])
    process.standardInput = input
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    // A write after the child died must fail rather than kill Macousel with SIGPIPE.
    _ = fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1)
    do {
      try process.run()
    } catch {
      Self.logger.error("Could not start the engine bridge: \(error, privacy: .public)")
      failures += 1
      return nil
    }
    let started = Child(process: process, input: input.fileHandleForWriting)
    child = started
    Task { await read(output.fileHandleForReading, from: process) }
    return started
  }

  private func read(_ handle: FileHandle, from process: Process) async {
    for await line in LineStream.lines(of: handle) {
      guard child?.process === process else { return }
      receive(line)
    }
    guard child?.process === process else { return }
    Self.logger.error("The engine bridge exited")
    discard(failing: true)
  }

  private func receive(_ line: String) {
    guard let answer = EngineBridgeAnswer.decode(line: line) else { return }
    failures = 0
    guard let id = answer.id else {
      listener?.yield(.event(line))
      return
    }
    deadlines.removeValue(forKey: id)?.cancel()
    guard let waiting = pending.removeValue(forKey: id) else { return }
    if answer.error == nil { listener?.yield(.answered) }
    waiting.resume(returning: .answered(answer))
  }

  private func expire(_ id: Int) {
    guard pending[id] != nil else { return }
    Self.logger.error("The engine bridge did not answer in time, restarting it")
    discard(failing: true)
  }

  private func discard(failing: Bool) {
    if failing { failures += 1 }
    if let child {
      self.child = nil
      try? child.input.close()
      if child.process.isRunning { child.process.terminate() }
    }
    deadlines.values.forEach { $0.cancel() }
    deadlines = [:]
    let waiting = pending
    pending = [:]
    waiting.values.forEach { $0.resume(returning: .failed) }
    listener?.finish()
    listener = nil
  }
}
