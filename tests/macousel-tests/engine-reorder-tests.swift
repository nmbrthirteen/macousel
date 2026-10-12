import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineReorderTests {
  private let log = EngineCallLog()
  private let commands: FakeEngineCommands
  private let strip: FakePaneruStrip
  private let sleeps: SleepCounter
  private let reorder: EngineReorder

  init() {
    let fake = FakeEngineCommands(log: log)
    let strip = FakePaneruStrip(columns: [[1], [2, 3], [4], [5, 6, 7]])
    let counter = SleepCounter()
    fake.strip = strip
    commands = fake
    self.strip = strip
    sleeps = counter
    reorder = EngineReorder(
      commands: fake,
      sleep: { _ in
        counter.count += 1
        await Task.yield()
      },
      now: { FrozenInstant.now })
  }

  private func expected(
    _ columns: [[UInt32]], moving window: UInt32, to target: DropTarget
  ) -> [[Int32]] {
    var model = Strip()
    for column in columns {
      for member in column { model.append(WindowID(member), width: .fixed(100)) }
    }
    for column in columns {
      for (row, member) in column.enumerated().dropFirst() {
        model.stack(WindowID(member), ontoColumnOf: WindowID(column[0]), atRow: row)
      }
    }
    let result = DropRule.applying(target, moving: WindowID(window), to: model)
    return result.columns.map { $0.windows.map { Int32($0.rawValue) } }
  }

  private func targets(for window: UInt32, among columns: [[UInt32]]) -> [DropTarget] {
    let positions = (0...columns.count + 1).map { DropTarget.column(position: $0) }
    let others = columns.flatMap { $0 }.filter { $0 != window }
    let stacks = others.flatMap { other in
      [VerticalNeighbor.above, .below].map { DropTarget.stack(onto: WindowID(other), side: $0) }
    }
    return positions + stacks
  }

  @Test func everyDropMatchesTheBuiltInEngineResult() async {
    let layout: [[UInt32]] = [[1], [2, 3], [4], [5, 6, 7]]
    for window in layout.flatMap({ $0 }) {
      for target in targets(for: window, among: layout) {
        strip.columns = layout.map { $0.map { Int32($0) } }
        strip.focused = 4

        _ = await reorder.move(WindowID(window), to: target)

        #expect(
          strip.columns == expected(layout, moving: window, to: target),
          "window \(window) onto \(target)")
        #expect(strip.errors.isEmpty, "window \(window) onto \(target)")
      }
    }
  }

  @Test func dropsStillLandWhenTheEngineLagsBehind() async {
    strip.lag = 3
    let target = DropTarget.stack(onto: WindowID(1), side: .above)

    _ = await reorder.move(WindowID(6), to: target)

    #expect(strip.columns == [[6, 1], [2, 3], [4], [5, 7]])
    #expect(sleeps.count > 0)
  }

  @Test func sendsOneCommandAtATimeInOrder() async {
    strip.focused = 4

    _ = await reorder.move(WindowID(3), to: .stack(onto: WindowID(4), side: .above))

    #expect(
      commands.sent == [
        ["window", "focus", "2"], ["window", "focus", "south"], ["window", "unstack"],
        ["window", "swap", "east"], ["window", "stack"], ["window", "swap", "north"],
      ])
  }

  @Test func usesSwapLastAndFirstForTheEnds() async {
    strip.columns = [[1], [2], [3], [4]]
    strip.focused = 1

    _ = await reorder.move(WindowID(1), to: .column(position: 3))
    _ = await reorder.move(WindowID(1), to: .column(position: 0))

    #expect(
      commands.sent == [["window", "swap", "last"], ["window", "swap", "first"]])
  }

  @Test func skipsFocusingWhenTheWindowIsAlreadyFocused() async {
    strip.focused = 2

    _ = await reorder.move(WindowID(2), to: .column(position: 3))

    #expect(commands.sent.first == ["window", "unstack"])
  }

  @Test func sendsNothingForANoOpDrop() async {
    let outcome = await reorder.move(WindowID(4), to: .column(position: 2))
    let nowhere = await reorder.move(WindowID(4), to: .nowhere)

    #expect(commands.sent.isEmpty)
    #expect(outcome == .nothingToDo(strip.snapshot))
    #expect(nowhere == .nothingToDo(strip.snapshot))
  }

  @Test func givesUpWhenTheFocusNeverArrives() async {
    strip.ignoresCommands = true

    let outcome = await reorder.move(WindowID(6), to: .column(position: 0))

    #expect(commands.sent == [["window", "focus", "4"]])
    #expect(sleeps.count == EnginePoll.polls)
    #expect(outcome.snapshot?.focusedWindowID == WindowID(1))
    #expect(outcome == .aborted(step: "focus", strip.snapshot))
  }

  @Test func abortsWithoutFurtherCommandsWhenAStepNeverShowsUp() async {
    strip.focused = 4
    strip.ignoresCommands = true

    let outcome = await reorder.move(WindowID(4), to: .column(position: 0))

    #expect(commands.sent == [["window", "swap", "first"]])
    #expect(sleeps.count == EnginePoll.polls)
    #expect(outcome == .aborted(step: "move column", strip.snapshot))
    #expect(strip.columns == [[1], [2, 3], [4], [5, 6, 7]])
  }

  @Test func ignoresADropWhileOneIsRunning() async {
    strip.lag = 1
    strip.focused = 4

    let first = Task { await reorder.move(WindowID(4), to: .column(position: 0)) }
    await Task.yield()
    let duringRun = await reorder.move(WindowID(1), to: .column(position: 3))
    _ = await first.value

    #expect(duringRun == .busy)
    #expect(strip.columns == [[4], [1], [2, 3], [5, 6, 7]])
    #expect(!reorder.isRunning)
  }

  @Test func acceptsANewDropOnceTheLastOneEnds() async {
    strip.focused = 4

    _ = await reorder.move(WindowID(4), to: .column(position: 0))
    _ = await reorder.move(WindowID(4), to: .column(position: 3))

    #expect(strip.columns == [[1], [2, 3], [5, 6, 7], [4]])
  }

  @Test func returnsNothingWithoutASnapshot() async {
    commands.strip = nil
    commands.snapshot = nil

    let result = await reorder.move(WindowID(4), to: .column(position: 0))

    #expect(result == .unavailable)
    #expect(commands.sent.isEmpty)
  }

  @Test func reportsACompletedMoveWithTheLatestSnapshot() async {
    strip.focused = 4

    let outcome = await reorder.move(WindowID(4), to: .column(position: 0))

    #expect(outcome == .completed(strip.snapshot))
  }

  @Test func restoresFocusStolenAfterTheFirstStepBeforeTheNextCommand() async {
    strip.afterApply = { strip, words in
      if words == ["window", "unstack"] { strip.focused = 5 }
    }

    let outcome = await reorder.move(WindowID(3), to: .column(position: 3))

    #expect(
      commands.sent == [
        ["window", "focus", "2"], ["window", "focus", "south"], ["window", "unstack"],
        ["window", "focus", "3"], ["window", "swap", "east"],
      ])
    #expect(strip.columns == [[1], [2], [4], [3], [5, 6, 7]])
    #expect(outcome == .completed(strip.snapshot))
  }

  @Test func abortsWithoutFurtherSendsWhenStolenFocusCannotBeRestored() async {
    strip.afterApply = { strip, words in
      guard words == ["window", "unstack"] else { return }
      strip.focused = 5
      strip.ignoresCommands = true
    }

    let outcome = await reorder.move(WindowID(3), to: .column(position: 3))

    #expect(commands.sent.last == ["window", "focus", "3"])
    #expect(!commands.sent.contains(["window", "swap", "east"]))
    #expect(outcome == .aborted(step: "move column", strip.snapshot))
  }

  @Test func neverSendsSwapNorthAfterTheRowVanishes() async {
    strip.columns = [[1], [2, 3]]
    strip.afterApply = { strip, words in
      if words == ["window", "focus", "south"] { strip.columns = [[1], [2], [3]] }
    }

    let outcome = await reorder.move(WindowID(3), to: .stack(onto: WindowID(2), side: .above))

    #expect(commands.sent == [["window", "focus", "2"], ["window", "focus", "south"]])
    #expect(strip.errors.isEmpty)
    #expect(outcome == .aborted(step: "move row", strip.snapshot))
  }

  @Test func neverSendsFocusSouthAtTheBottomOfAColumn() async {
    strip.columns = [[1], [2, 3]]
    strip.afterApply = { strip, words in
      if words == ["window", "focus", "2"] { strip.columns = [[1], [2], [3]] }
    }

    let outcome = await reorder.move(WindowID(3), to: .stack(onto: WindowID(2), side: .above))

    #expect(commands.sent == [["window", "focus", "2"]])
    #expect(strip.errors.isEmpty)
    #expect(outcome == .aborted(step: "focus", strip.snapshot))
  }

  @Test func stopsPollingAtTheDeadlineWhenEachPollIsSlow() async {
    let clock = StepClock()
    let counter = SleepCounter()
    let slow = EngineReorder(
      commands: commands,
      sleep: { _ in
        counter.count += 1
        clock.now = clock.now.advanced(by: .seconds(1))
      },
      now: { clock.now })
    strip.ignoresCommands = true

    let outcome = await slow.move(WindowID(6), to: .column(position: 0))

    #expect(counter.count == 2)
    #expect(outcome == .aborted(step: "focus", strip.snapshot))
  }
}

@MainActor
final class SleepCounter {
  var count = 0
}

@MainActor
final class StepClock {
  var now = ContinuousClock.now
}
