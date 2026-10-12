import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineSettlerTests {
  private let commands = FakeEngineCommands(log: EngineCallLog())
  private let strip = FakePaneruStrip(columns: [[1], [2], [3]])
  private let clock = StepClock()
  private let counter = SleepCounter()

  init() {
    commands.strip = strip
  }

  private func settler(secondsPerSleep: Double) -> EngineSettler {
    let clock = clock
    let counter = counter
    return EngineSettler(
      commands: commands,
      sleep: { _ in
        counter.count += 1
        clock.now = clock.now.advanced(by: .seconds(secondsPerSleep))
      },
      now: { clock.now })
  }

  @Test func settlesAsSoonAsTheStructureMatches() async {
    let expected: [[WindowID]] = [[WindowID(1)], [WindowID(2)], [WindowID(3)]]

    let settled = await settler(secondsPerSleep: 0).settles(on: expected)

    #expect(settled)
    #expect(counter.count == 0)
  }

  @Test func givesUpAfterThePollCountWhenPollsAreFast() async {
    let settled = await settler(secondsPerSleep: 0).settles(on: [[WindowID(9)]])

    #expect(!settled)
    #expect(counter.count == EnginePoll.polls)
  }

  @Test func givesUpAtTheDeadlineWhenPollsAreSlow() async {
    let settled = await settler(secondsPerSleep: 1).settles(on: [[WindowID(9)]])

    #expect(!settled)
    #expect(counter.count == 2)
  }

  @Test func snapSendsTheSnapCommand() async {
    await settler(secondsPerSleep: 0).snap()

    #expect(commands.sent == [["window", "snap"]])
  }
}
