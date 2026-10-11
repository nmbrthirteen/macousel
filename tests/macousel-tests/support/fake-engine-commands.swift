@testable import Macousel

@MainActor
final class FakeEngineCommands: EngineCommanding {
  var isAlive = false
  var quitEndsIt = true
  var snapshot: EngineSnapshot?
  private(set) var sent: [[String]] = []
  private let log: EngineCallLog

  init(log: EngineCallLog) {
    self.log = log
  }

  func send(_ words: [String]) async {
    sent.append(words)
    log.append("send " + words.joined(separator: " "))
    if words == ["quit"] && quitEndsIt { isAlive = false }
  }

  func fetchSnapshot() async -> EngineSnapshot? {
    snapshot
  }

  func isAnswering() async -> Bool {
    isAlive
  }
}

@MainActor
final class FakeEngineEvents: EngineEventSource {
  var onEvent: ((EngineEvent) -> Void)?
  private(set) var startCount = 0
  private(set) var stopCount = 0

  func start() {
    startCount += 1
  }

  func stop() {
    stopCount += 1
  }
}
