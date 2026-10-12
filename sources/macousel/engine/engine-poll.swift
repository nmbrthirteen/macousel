struct EnginePoll {
  static let polls = 50
  static let interval = Duration.milliseconds(20)
  static let deadline = Duration.seconds(2)

  let commands: any EngineCommanding
  let sleep: (Duration) async throws -> Void
  let now: () -> ContinuousClock.Instant

  func until(
    _ condition: (EngineSnapshot) -> Bool, observing observe: (EngineSnapshot) -> Void = { _ in }
  ) async -> Bool {
    let limit = now().advanced(by: Self.deadline)
    for _ in 0..<Self.polls {
      if let fetched = await commands.fetchSnapshot() {
        observe(fetched)
        if condition(fetched) { return true }
      }
      guard now() < limit else { return false }
      do {
        try await sleep(Self.interval)
      } catch {
        return false
      }
    }
    return false
  }
}
