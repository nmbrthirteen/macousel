import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct GrowthHoldTests {
  private func settle(_ fixture: ControllerFixture, trace: inout PlacementTrace) -> Int {
    var ticks = 0
    while fixture.clock.isRunning && ticks < 1200 {
      fixture.clock.tick(by: 1.0 / 120)
      trace.record(fixture.placer.submissions)
      ticks += 1
    }
    return ticks
  }

  private func launched(
    columns: CGWindowID, speed: AnimationSpeed = .fast
  ) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.animationSpeed = speed }
    let row = fixture.openRow(columns)
    fixture.launch()
    while fixture.clock.isRunning { fixture.clock.tick(by: 1.0 / 120) }
    return (fixture, row)
  }

  private func trace(_ fixture: ControllerFixture, _ row: [FakeWindow]) -> PlacementTrace {
    PlacementTrace(
      frames: fixture.frames(of: row), consumed: fixture.placer.submissions.count)
  }

  @Test func aWiderColumnKeepsItsOldWidthUntilItsRightNeighbourHasCleared() throws {
    let (fixture, row) = try launched(columns: 2)
    let oldWidth = try #require(row[0].frame).width
    var trace = trace(fixture, row)

    fixture.manager.perform(.cycleWidth)
    trace.record(fixture.placer.submissions)
    var widths = [try #require(row[0].frame).width]
    while fixture.clock.isRunning && widths.count < 1200 {
      fixture.clock.tick(by: 1.0 / 120)
      trace.record(fixture.placer.submissions)
      widths.append(try #require(row[0].frame).width)
    }

    var expected = ExpectedStrip()
    expected.append(1, .fraction(2.0 / 3.0))
    expected.append(2)
    let newWidth = try #require(expected.frame(of: 1)).width
    let firstGrown = try #require(widths.firstIndex(of: newWidth))
    #expect(newWidth > oldWidth)
    #expect(widths[0] == oldWidth)
    #expect(firstGrown > 1)
    #expect(widths[..<firstGrown].allSatisfy { $0 == oldWidth })
    #expect(widths[firstGrown...].allSatisfy { $0 == newWidth })
    #expect(trace.worstOverlap <= GrowthGate.overlapTolerance)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func theLastColumnGrowingIntoEmptySpaceIsResizedOnTheFirstFrame() throws {
    let (fixture, row) = try launched(columns: 2)
    fixture.manager.perform(.focusLast)
    while fixture.clock.isRunning { fixture.clock.tick(by: 1.0 / 120) }
    let oldWidth = try #require(row[1].frame).width

    fixture.manager.perform(.cycleWidth)

    #expect(try #require(row[1].frame).width > oldWidth)
  }

  @Test func aShrinkingColumnIsResizedOnTheFirstFrame() throws {
    let (fixture, row) = try launched(columns: 2)
    let oldWidth = try #require(row[0].frame).width

    fixture.manager.perform(.narrower)

    #expect(try #require(row[0].frame).width < oldWidth)
  }

  @Test func anAdmittedWindowIsNeverHeldAtAnOldSize() async throws {
    let (fixture, _) = try launched(columns: 1)

    let newcomer = fixture.open(2, app: .terminal, atX: 700)

    #expect(await fixture.becomes { !newcomer.framesSet.isEmpty })
    let first = try #require(newcomer.framesSet.first)
    #expect(first.width == (try #require(ExpectedStrip(columns: [1, 2]).frame(of: 2)).width))
  }

  @Test func inAStackTheShrinkingRowIsResizedFirstAndTheGrowingRowOnALaterFrame() throws {
    let (fixture, row) = try launched(columns: 2)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    while fixture.clock.isRunning { fixture.clock.tick(by: 1.0 / 120) }
    fixture.manager.perform(.focusUp)
    while fixture.clock.isRunning { fixture.clock.tick(by: 1.0 / 120) }
    let oldTopHeight = try #require(row[0].frame).height
    let oldBottomHeight = try #require(row[1].frame).height
    let baseline = fixture.placer.submissions.count
    var trace = trace(fixture, row)

    fixture.manager.perform(.taller)
    trace.record(fixture.placer.submissions)
    #expect(try #require(row[1].frame).height < oldBottomHeight)
    #expect(try #require(row[0].frame).height == oldTopHeight)
    _ = settle(fixture, trace: &trace)

    let submissions = fixture.placer.submissions[baseline...]
    let shrink = try #require(
      submissions.firstIndex { $0.window == 2 && $0.frame.height < oldBottomHeight })
    let grow = try #require(
      submissions.firstIndex { $0.window == 1 && $0.frame.height > oldTopHeight })
    #expect(shrink < grow)
    #expect(trace.worstOverlap <= GrowthGate.overlapTolerance)
    #expect(try #require(row[0].frame).height > oldTopHeight)
  }

  @Test func withAnimationOffTheNewSizeLandsAtOnce() throws {
    let (fixture, row) = try launched(columns: 2, speed: .off)

    fixture.manager.perform(.cycleWidth)

    var expected = ExpectedStrip()
    expected.append(1, .fraction(2.0 / 3.0))
    expected.append(2)
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(!fixture.clock.isRunning)
  }

  @Test(arguments: [AnimationSpeed.fast, .standard, .relaxed])
  func aSettledWorkspaceNeverLeavesAWindowAtItsOldSize(speed: AnimationSpeed) throws {
    let (fixture, row) = try launched(columns: 3, speed: speed)
    let (reference, referenceRow) = try launched(columns: 3, speed: .off)
    var trace = trace(fixture, row)
    let actions: [Action] = [.cycleWidth, .cycleWidth, .wider, .focusRight, .cycleWidth, .narrower]

    for action in actions {
      fixture.manager.perform(action)
      reference.manager.perform(action)
      _ = settle(fixture, trace: &trace)

      #expect(!fixture.clock.isRunning)
      #expect(fixture.frames(of: row) == reference.frames(of: referenceRow))
    }
    #expect(trace.worstOverlap <= GrowthGate.overlapTolerance)
  }
}
