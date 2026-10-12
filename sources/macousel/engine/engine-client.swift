import Foundation

final class EngineClient: EngineCommanding {
  private let locate: () -> URL?
  private let locateBridge: () -> URL?
  private let service: String
  private let runner: HelperRunner

  init(
    service: String, runner: HelperRunner = HelperRunner(), locate: @escaping () -> URL?,
    locateBridge: @escaping () -> URL? = { nil }
  ) {
    self.service = service
    self.runner = runner
    self.locate = locate
    self.locateBridge = locateBridge
  }

  func send(_ words: [String]) async {
    _ = await run(["send-cmd"] + words)
  }

  func fetchSnapshot() async -> EngineSnapshot? {
    if let bridged = await fetchBridgedSnapshot() { return bridged }
    guard let output = await run(["query", "state"]), output.status == 0 else { return nil }
    return EngineSnapshot.decode(output.text)
  }

  private func fetchBridgedSnapshot() async -> EngineSnapshot? {
    guard let bridge = locateBridge(), let output = await run(bridge, []), output.status == 0
    else { return nil }
    return EngineSnapshot.decode(bridged: output.text)
  }

  func isAnswering() async -> Bool {
    await run(["query", "active"])?.status == 0
  }

  private func run(_ arguments: [String]) async -> ProcessOutput? {
    guard let helper = locate() else { return nil }
    return await run(helper, arguments)
  }

  private func run(_ helper: URL, _ arguments: [String]) async -> ProcessOutput? {
    var environment = ProcessInfo.processInfo.environment
    environment[EngineService.variable] = service
    return await runner.run(helper, arguments: arguments, environment: environment)
  }
}
