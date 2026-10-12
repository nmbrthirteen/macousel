import StripCore

struct EngineSettler {
  let commands: any EngineCommanding
  let sleep: (Duration) async throws -> Void
  var now: () -> ContinuousClock.Instant = { ContinuousClock.now }

  func settles(on expected: [[WindowID]]) async -> Bool {
    let poll = EnginePoll(commands: commands, sleep: sleep, now: now)
    return await poll.until { $0.tiledColumns.windowIDs == expected }
  }

  func snap() async {
    await commands.send(["window", "snap"])
  }
}
