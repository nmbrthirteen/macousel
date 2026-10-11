struct EngineReport {
  var selected: WindowEngine
  var version: String
  var helperFound: Bool
  var state: String
  var restartCount: Int
  var config: String
  var logTail: String

  var text: String {
    [
      "Engine: \(selected.title)",
      "Engine version: \(version)",
      "Engine helper found: \(helperFound ? "yes" : "no")",
      "Engine state: \(state), restarts \(restartCount)",
      "Engine configuration\n\(config)",
      "Engine log, last 200 lines\n\(logTail)",
    ].joined(separator: "\n\n")
  }
}
