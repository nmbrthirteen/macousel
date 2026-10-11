import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SlowAppPresentationTests {
  private static let apps: [FakeApp] = [.editor, .browser, .terminal, .floater, .editor, .browser]
  private static let frameStep = 1.0 / 120

  private func launched(
    columns: Int, speed: AnimationSpeed = .fast
  ) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.animationSpeed = speed }
    let row = (0..<columns).map { index in
      fixture.open(
        CGWindowID(index + 1), app: Self.apps[index], atX: CGFloat(index + 1) * 200,
        activating: index == 0)
    }
    fixture.launch()
    settle(fixture)
    return (fixture, row)
  }

  private func settle(_ fixture: ControllerFixture) {
    var ticks = 0
    while fixture.clock.isRunning && ticks < 1200 {
      fixture.clock.tick(by: Self.frameStep)
      ticks += 1
    }
  }

  private func finalFrames(
    columns: Int, after actions: [Action]
  ) throws -> [CGWindowID: CGRect] {
    let (fixture, row) = try launched(columns: columns, speed: .off)
    for action in actions { fixture.manager.perform(action) }
    return fixture.frames(of: row)
  }

  @Test func aSlowAppsWindowIsSubmittedOnceAtItsFinalFrameWhileOthersAnimate() throws {
    let (fixture, row) = try launched(columns: 3)
    let initial = try #require(row[1].frame)
    fixture.placer.setSlow(true, forAppOf: row[1])
    let before = row.map { $0.framesSet.count }
    let final = try finalFrames(columns: 3, after: [.focusLast])

    fixture.manager.perform(.focusLast)
    #expect(row[1].framesSet.count - before[1] == 1)
    #expect(row[1].framesSet.last == final[2])
    settle(fixture)

    #expect(final[2] != initial)
    #expect(row[1].framesSet.count - before[1] == 1)
    #expect(row[2].framesSet.count - before[2] > 3)
    #expect(fixture.frames(of: row) == final)
  }

  @Test func markingTheAppResponsiveAgainRestoresPerFrameSubmission() throws {
    let (fixture, row) = try launched(columns: 3)
    fixture.placer.setSlow(true, forAppOf: row[1])
    fixture.manager.perform(.focusLast)
    settle(fixture)
    fixture.placer.setSlow(false, forAppOf: row[1])
    let before = row[1].framesSet.count

    fixture.manager.perform(.focusFirst)
    settle(fixture)

    #expect(row[1].framesSet.count - before > 3)
    #expect(fixture.frames(of: row) == (try finalFrames(columns: 3, after: [.focusLast, .focusFirst])))
  }

  @Test func aSlowAppsWindowThatWillBeParkedGoesStraightToItsParkedFrame() throws {
    let (fixture, row) = try launched(columns: 5)
    fixture.placer.setSlow(true, forAppOf: row[0])
    let before = row[0].framesSet.count
    let final = try finalFrames(columns: 5, after: [.focusLast])
    let parked = try #require(final[1])

    fixture.manager.perform(.focusLast)
    settle(fixture)

    #expect(parked.maxX <= fixture.display.frame.minX + ParkingPolicy.visibleSliver)
    #expect(row[0].framesSet.count - before == 1)
    #expect(row[0].framesSet.last == parked)
  }

  @Test func responsiveAppsReceiveEveryFrameWhateverTheSlowAppDoes() throws {
    func framesReceived(markingSlow: Bool) throws -> [Int] {
      let (fixture, row) = try launched(columns: 4)
      if markingSlow { fixture.placer.setSlow(true, forAppOf: row[1]) }
      let before = row.map { $0.framesSet.count }
      fixture.manager.perform(.focusLast)
      settle(fixture)
      return zip(row, before).map { $0.framesSet.count - $1 }
    }

    let reference = try framesReceived(markingSlow: false)
    let withSlowApp = try framesReceived(markingSlow: true)

    #expect(reference[2] > 3)
    for index in [0, 2, 3] { #expect(withSlowApp[index] == reference[index]) }
    #expect(withSlowApp[1] == 1)
  }

  @Test func aSlowWindowIsSubmittedNoMoreOftenThanTheLimitDuringASwipeAndOnceAtTheEnd() throws {
    func swipe(markingSlow: Bool) throws -> (ControllerFixture, [FakeWindow], Int, Int) {
      let (fixture, row) = try launched(columns: 6, speed: .fast)
      if markingSlow { fixture.placer.setSlow(true, forAppOf: row[2]) }
      let before = row[2].framesSet.count
      fixture.gestures.onScroll?(-40, .began)
      for _ in 0..<30 {
        fixture.clock.advance(by: .milliseconds(20))
        fixture.gestures.onScroll?(-40, .changed)
      }
      let duringSwipe = row[2].framesSet.count - before
      fixture.clock.advance(by: .milliseconds(20))
      fixture.gestures.onScroll?(0, .ended)
      let afterEnd = row[2].framesSet.count - before - duringSwipe
      settle(fixture)
      return (fixture, row, duringSwipe, afterEnd)
    }

    let (fixture, row, duringSwipe, afterEnd) = try swipe(markingSlow: true)
    let (reference, referenceRow, referenceDuringSwipe, _) = try swipe(markingSlow: false)

    let swipeDuration = Duration.milliseconds(20 * 30)
    let limit = Int(swipeDuration / SlowSubmissionLimiter.trackingInterval) + 1
    #expect(referenceDuringSwipe > limit)
    #expect(duringSwipe >= 1)
    #expect(duringSwipe <= limit)
    #expect(afterEnd == 1)
    #expect(fixture.frames(of: row) == reference.frames(of: referenceRow))
  }

  @Test func aSlowNeighbourDoesNotLetAGrowingColumnOverlapIt() throws {
    let (fixture, row) = try launched(columns: 2)
    fixture.placer.setSlow(true, forAppOf: row[1])
    var trace = PlacementTrace(
      frames: fixture.frames(of: row), consumed: fixture.placer.submissions.count)

    fixture.manager.perform(.cycleWidth)
    trace.record(fixture.placer.submissions)
    while fixture.clock.isRunning {
      fixture.clock.tick(by: Self.frameStep)
      trace.record(fixture.placer.submissions)
    }

    #expect(trace.worstOverlap <= GrowthGate.overlapTolerance)
    #expect(fixture.frames(of: row) == (try finalFrames(columns: 2, after: [.cycleWidth])))
  }

  @Test func aGrowingSlowWindowWaitsForItsAnimatingNeighbourToClear() throws {
    let (fixture, row) = try launched(columns: 2)
    fixture.placer.setSlow(true, forAppOf: row[0])
    let oldWidth = try #require(row[0].frame).width
    var trace = PlacementTrace(
      frames: fixture.frames(of: row), consumed: fixture.placer.submissions.count)

    fixture.manager.perform(.cycleWidth)
    trace.record(fixture.placer.submissions)
    #expect(try #require(row[0].frame).width == oldWidth)
    while fixture.clock.isRunning {
      fixture.clock.tick(by: Self.frameStep)
      trace.record(fixture.placer.submissions)
    }

    #expect(trace.worstOverlap <= GrowthGate.overlapTolerance)
    #expect(try #require(row[0].frame).width > oldWidth)
    #expect(fixture.frames(of: row) == (try finalFrames(columns: 2, after: [.cycleWidth])))
  }
}
