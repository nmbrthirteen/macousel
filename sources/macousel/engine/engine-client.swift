import Foundation

final class EngineClient: EngineCommanding {
  private let locate: () -> URL?
  private let service: String
  private let runner: HelperRunner

  init(service: String, runner: HelperRunner = HelperRunner(), locate: @escaping () -> URL?) {
    self.service = service
    self.runner = runner
    self.locate = locate
  }

  func send(_ words: [String]) async {
    _ = await run(["send-cmd"] + words)
  }

  func fetchSnapshot() async -> EngineSnapshot? {
    guard let output = await run(["query", "state"]), output.status == 0 else { return nil }
    return EngineSnapshot.decode(output.text)
  }

  func isAnswering() async -> Bool {
    await run(["query", "active"])?.status == 0
  }

  private func run(_ arguments: [String]) async -> ProcessOutput? {
    guard let helper = locate() else { return nil }
    var environment = ProcessInfo.processInfo.environment
    environment[EngineService.variable] = service
    return await runner.run(helper, arguments: arguments, environment: environment)
  }
}
