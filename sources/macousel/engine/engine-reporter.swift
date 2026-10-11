import Foundation

struct EngineReporter {
  static let logLines = 200

  let version: String
  let locate: () -> URL?
  let supervisor: EngineSupervisor
  let sync: EngineConfigSync
  let log: EngineLog

  func report(selected: WindowEngine) -> EngineReport {
    EngineReport(
      selected: selected, version: version, helperFound: locate() != nil,
      state: supervisor.state.description, restartCount: supervisor.restartCount,
      config: sync.currentText, logTail: log.lastLines(Self.logLines))
  }
}
