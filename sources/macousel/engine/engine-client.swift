import Foundation
import WindowSystem
import os

final class EngineClient: EngineCommanding {
  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

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
    guard let output = await run(["send-cmd"] + words) else { return }
    if output.status != 0 {
      let command = words.first ?? ""
      Self.logger.error(
        "The engine refused \(command, privacy: .public), status \(output.status)")
    }
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
    let environment = ChildEnvironment.current(adding: [EngineService.variable: service])
    guard let output = await runner.run(helper, arguments: arguments, environment: environment)
    else {
      Self.logger.error("Could not run \(helper.lastPathComponent, privacy: .public)")
      return nil
    }
    return output
  }
}
