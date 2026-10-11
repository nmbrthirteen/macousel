import Foundation
import Testing

@testable import Macousel

@MainActor
struct SettingsPreviewLoopTests {
  @MainActor private final class Gate {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
    private(set) var sleepCount = 0

    init() {
      (stream, continuation) = AsyncStream<Void>.makeStream()
    }

    func hold(_ duration: Duration) async throws {
      sleepCount += 1
      for await _ in stream {}
      try Task.checkCancellation()
    }
  }

  private func layoutLoop(sleep: @escaping PreviewSleep) -> FocusLoop {
    FocusLoop(restingColumn: 1, alternateColumn: 3, interval: .seconds(2), sleep: sleep)
  }

  @Test func startsOnTheRestingColumn() {
    let loop = layoutLoop { _ in }
    #expect(loop.focusedColumn == 1)
    #expect(loop.trail == [1])
    #expect(!loop.isRunning)
  }

  @Test func alternatesBetweenTheTwoColumnsOnEachInterval() async {
    let scripted = ScriptedSleep(allowedCalls: 3, start: Date())
    let loop = layoutLoop { try await scripted.sleep($0) }
    await loop.run()
    #expect(loop.trail == [3, 1, 3])
    #expect(loop.focusedColumn == 3)
    #expect(scripted.durations.prefix(3).allSatisfy { $0 == .seconds(2) })
  }

  @Test func trailKeepsOnlyTheLastThreeFocusPositions() {
    let loop = layoutLoop { _ in }
    for _ in 0..<5 { loop.advance() }
    #expect(loop.trail.count == 3)
    #expect(loop.trail == [3, 1, 3])
  }

  @Test func motionLoopMovesOneColumnRightAndBack() async {
    let scripted = ScriptedSleep(allowedCalls: 2, start: Date())
    let loop = FocusLoop(
      restingColumn: 1, alternateColumn: 2, interval: .milliseconds(800)
    ) { try await scripted.sleep($0) }
    await loop.run()
    #expect(loop.trail == [1, 2, 1])
    #expect(scripted.durations.first == .milliseconds(800))
  }

  @Test func startRunsTheLoopAndStopHaltsItAndRestoresTheRestingColumn() async {
    let gate = Gate()
    let loop = layoutLoop { try await gate.hold($0) }
    loop.start(reduceMotion: false)
    #expect(loop.isRunning)
    loop.advance()
    #expect(loop.focusedColumn == 3)
    loop.stop()
    #expect(!loop.isRunning)
    #expect(loop.trail == [1])
  }

  @Test func reduceMotionKeepsTheLoopStaticOnTheRestingColumn() {
    let gate = Gate()
    let loop = layoutLoop { try await gate.hold($0) }
    loop.start(reduceMotion: true)
    #expect(!loop.isRunning)
    #expect(loop.focusedColumn == 1)
    #expect(gate.sleepCount == 0)
  }

  @Test func switchingToReduceMotionStopsARunningLoop() {
    let gate = Gate()
    let loop = layoutLoop { try await gate.hold($0) }
    loop.start(reduceMotion: false)
    loop.advance()
    loop.start(reduceMotion: true)
    #expect(!loop.isRunning)
    #expect(loop.trail == [1])
  }
}
