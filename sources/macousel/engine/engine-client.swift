import Foundation
import WindowSystem
import os

final class EngineClient: EngineCommanding {
  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  private let locate: () -> URL?
  private let locateBridge: () -> URL?
  private let service: String
  private let runner: HelperRunner
  private let bridge: EngineBridgeConnection?
  private static var loggedBridgeFallback = false
  // Commands run one at a time in the order they were issued, so a fast key repeat or swipe
  // cannot reach the engine out of order.
  private var lastCommand: Task<Void, Never>?

  init(
    service: String, runner: HelperRunner = HelperRunner(), locate: @escaping () -> URL?,
    locateBridge: @escaping () -> URL? = { nil }, bridge: EngineBridgeConnection? = nil
  ) {
    self.service = service
    self.runner = runner
    self.locate = locate
    self.locateBridge = locateBridge
    self.bridge = bridge
  }

  func send(_ words: [String]) async {
    let previous = lastCommand
    let command = Task {
      await previous?.value
      await deliver(words)
    }
    lastCommand = command
    await command.value
  }

  private func deliver(_ words: [String]) async {
    switch await bridge?.ask(.command(words)) ?? .unavailable {
    // The bridge links the published Paneru, which cannot parse a command only a patch adds.
    // The patched engine binary can.
    case .answered(let answer) where answer.unparsed:
      break
    case .answered(let answer):
      if let error = answer.error {
        Self.logger.error(
          "The engine refused \(words.first ?? "", privacy: .public): \(error, privacy: .public)")
      }
      return
    case .failed:
      return
    case .unavailable:
      break
    }
    guard let output = await run(["send-cmd"] + words) else { return }
    if output.status != 0 {
      let command = words.first ?? ""
      Self.logger.error(
        "The engine refused \(command, privacy: .public), status \(output.status)")
    }
  }

  func fetchSnapshot() async -> EngineSnapshot? {
    switch await bridge?.ask(.snapshot) ?? .unavailable {
    case .answered(let answer): return answer.snapshot
    case .failed: return nil
    case .unavailable: break
    }
    if let bridged = await fetchBridgedSnapshot() { return bridged }
    if !Self.loggedBridgeFallback {
      Self.loggedBridgeFallback = true
      Self.logger.error("The engine bridge gave no state, falling back to query state")
    }
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
