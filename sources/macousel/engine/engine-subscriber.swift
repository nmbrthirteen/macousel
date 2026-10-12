import Foundation

final class EngineSubscriber: EngineEventSource {
  var onEvent: ((EngineEvent) -> Void)?
  var onConnect: (() -> Void)?

  private let locate: () -> URL?
  private let service: String
  private let retryDelay: Duration
  private var task: Task<Void, Never>?
  private var process: Process?

  init(service: String, retryDelay: Duration = .seconds(1), locate: @escaping () -> URL?) {
    self.service = service
    self.retryDelay = retryDelay
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
  }

  private func keepSubscribed() async {
    while !Task.isCancelled {
      await subscribeOnce()
      try? await Task.sleep(for: retryDelay)
    }
  }

  private func subscribeOnce() async {
    guard let helper = locate() else { return }
    let child = Process()
    let output = Pipe()
    child.executableURL = helper
    child.arguments = ["subscribe"]
    child.environment = ProcessInfo.processInfo.environment.merging([EngineService.variable: service]) {
      _, override in override
    }
    child.standardInput = FileHandle.nullDevice
    child.standardError = FileHandle.nullDevice
    child.standardOutput = output
    guard (try? child.run()) != nil else { return }
    process = child
    onConnect?()
    do {
      for try await line in output.fileHandleForReading.bytes.lines {
        if let event = EngineEvent.decode(line: line) { onEvent?(event) }
      }
    } catch {
      return
    }
  }
}
