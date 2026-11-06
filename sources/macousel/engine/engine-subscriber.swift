import Foundation
import WindowSystem
import os

final class EngineSubscriber: EngineEventSource {
  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  var onEvent: ((EngineEvent) -> Void)?
  var onConnect: (() -> Void)?

  private let locate: () -> URL?
  private let service: String
  private let retryDelay: Duration
  private let bridge: EngineBridgeConnection?
  private var task: Task<Void, Never>?
  private var process: Process?

  init(
    service: String, retryDelay: Duration = .seconds(1), bridge: EngineBridgeConnection? = nil,
    locate: @escaping () -> URL?
  ) {
    self.service = service
    self.retryDelay = retryDelay
    self.bridge = bridge
    self.locate = locate
  }

  func start() {
    guard task == nil else { return }
    task = Task { await keepSubscribed() }
  }

  func stop() {
    task?.cancel()
    task = nil
    process?.terminate()
    process = nil
    bridge?.close()
  }

  private func keepSubscribed() async {
    while !Task.isCancelled {
      await subscribeOnce()
      try? await Task.sleep(for: retryDelay)
    }
  }

  private func subscribeOnce() async {
    guard let signals = bridge?.signals() else {
      await spawnSubscriber()
      return
    }
    var connected = false
    for await signal in signals {
      announce(&connected)
      if case .event(let line) = signal { deliver(line) }
    }
  }

  private func spawnSubscriber() async {
    guard let helper = locate() else { return }
    let child = Process()
    let output = Pipe()
    child.executableURL = helper
    child.arguments = ["subscribe"]
    child.environment = ChildEnvironment.current(adding: [EngineService.variable: service])
    child.standardInput = FileHandle.nullDevice
    child.standardError = FileHandle.nullDevice
    child.standardOutput = output
    do {
      try child.run()
    } catch {
      Self.logger.error("Could not subscribe to engine events: \(error, privacy: .public)")
      return
    }
    process = child
    var connected = false
    do {
      for try await line in output.fileHandleForReading.bytes.lines {
        announce(&connected)
        deliver(line)
      }
    } catch {
      Self.logger.error("The engine event stream failed: \(error, privacy: .public)")
    }
  }

  // Reconnecting refreshes the world, so wait for proof the engine answers.
  private func announce(_ connected: inout Bool) {
    guard !connected else { return }
    connected = true
    onConnect?()
  }

  private func deliver(_ line: String) {
    if let event = EngineEvent.decode(line: line) { onEvent?(event) }
  }
}
