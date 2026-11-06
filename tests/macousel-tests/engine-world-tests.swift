import Testing

@testable import Macousel

@Suite @MainActor
struct EngineWorldTests {
  private let log = EngineCallLog()

  @Test func retriesOnceAfterAFailedFetch() async throws {
    let commands = FakeEngineCommands(log: log)
    let fixture = try #require(EngineSnapshot.decode(EngineFixtures.stateJSON))
    var sleeps: [Duration] = []
    let world = EngineWorld(
      commands: commands,
      sleep: { duration in
        sleeps.append(duration)
        commands.snapshot = fixture
      })

    world.refresh()
    while world.snapshot == nil { await Task.yield() }

    #expect(sleeps == [EngineWorld.retryDelay])
    #expect(world.snapshot == fixture)
  }

  @Test func stopsRetryingAfterAFewConsecutiveFailures() async {
    let commands = FakeEngineCommands(log: log)
    var sleeps = 0
    let world = EngineWorld(commands: commands, sleep: { _ in sleeps += 1 })

    world.refresh()
    for _ in 0..<50 { await Task.yield() }

    #expect(sleeps == EngineWorld.maximumRetries)
    #expect(world.snapshot == nil)
  }
}
