import StripCore

struct EngineSettler {
  static let polls = 10
  static let interval = Duration.milliseconds(100)

  let commands: any EngineCommanding
  let sleep: (Duration) async throws -> Void

  func settles(on expected: [[WindowID]]) async -> Bool {
    for _ in 0..<Self.polls {
      if let fetched = await commands.fetchSnapshot(), fetched.tiledColumns.windowIDs == expected {
        return true
      }
      do {
        try await sleep(Self.interval)
      } catch {
        return false
      }
    }
    return false
  }
}
