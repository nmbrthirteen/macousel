import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct AnimationTests {
  private func launchedRow(
    speed: AnimationSpeed, configure: (inout Preferences) -> Void = { _ in }
  ) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture {
      $0.animationSpeed = speed
      configure(&$0)
    }
    let row = fixture.openRow(3)
    fixture.launch()
    return (fixture, row)
  }

  private func finalFrames() -> [CGWindowID: CGRect] {
    var expected = ExpectedStrip(columns: [1, 2, 3])
    expected.focus(3)
    return expected.frames
  }

  @Test func relayoutLandsFinalFramesWithoutClockTicksWhenAnimationIsOff() throws {
    let (fixture, row) = try launchedRow(speed: .off)

    fixture.manager.perform(.focusLast)

    #expect(fixture.frames(of: row) == finalFrames())
    #expect(fixture.clock.startCount == 0)
    #expect(!fixture.clock.isRunning)
  }

  @Test(arguments: [true, false])
  func reduceMotionAndLowPowerModeSkipAnimation(reducesMotion: Bool) throws {
    let fixture = try ControllerFixture { $0.animationSpeed = .fast }
    fixture.environment.reducesMotion = reducesMotion
    fixture.environment.isLowPowerModeEnabled = !reducesMotion
    let row = fixture.openRow(3)
    fixture.launch()

    fixture.manager.perform(.focusLast)

    #expect(fixture.frames(of: row) == finalFrames())
    #expect(fixture.clock.startCount == 0)
  }

  @Test func tickingMovesFramesMonotonicallyTowardTheTarget() throws {
    let (fixture, row) = try launchedRow(speed: .fast)
    while fixture.clock.isRunning { fixture.clock.tick() }
    let start = try #require(row[2].frame)

    fixture.manager.perform(.focusLast)

    #expect(fixture.clock.isRunning)
    let firstFrame = try #require(row[2].frame)
    #expect(firstFrame.minX < start.minX)
    #expect(firstFrame.minX > start.minX - 100)
    var positions = [start.minX, firstFrame.minX]
    while fixture.clock.isRunning && positions.count < 600 {
      fixture.clock.tick()
      positions.append(try #require(row[2].frame).minX)
    }
    let target = try #require(finalFrames()[3]).minX
    #expect(positions.count > 3)
    #expect(zip(positions, positions.dropFirst()).allSatisfy { $0 >= $1 })
    #expect(positions.last == target)
  }

  @Test func clockStopsAndFinalFramesLandWhenMotionSettles() throws {
    let (fixture, row) = try launchedRow(speed: .fast)
    while fixture.clock.isRunning { fixture.clock.tick() }

    fixture.manager.perform(.focusLast)
    var ticks = 0
    while fixture.clock.isRunning && ticks < 600 {
      fixture.clock.tick()
      ticks += 1
    }

    #expect(!fixture.clock.isRunning)
    #expect(ticks < 600)
    #expect(fixture.frames(of: row) == finalFrames())
  }

  @Test func slowerSpeedNeedsMoreTicksToSettle() throws {
    func ticksToSettle(_ speed: AnimationSpeed) throws -> Int {
      let (fixture, _) = try launchedRow(speed: speed)
      while fixture.clock.isRunning { fixture.clock.tick() }
      fixture.manager.perform(.focusLast)
      var ticks = 0
      while fixture.clock.isRunning && ticks < 1200 {
        fixture.clock.tick()
        ticks += 1
      }
      return ticks
    }

    let fast = try ticksToSettle(.fast)
    let relaxed = try ticksToSettle(.relaxed)

    #expect(relaxed > fast)
  }

  @Test func windowsEnterFromTheirCurrentPositionWhenAnimationIsOn() throws {
    let fixture = try ControllerFixture { $0.animationSpeed = .fast }
    let window = fixture.open(1, atX: 300, activating: true)

    fixture.launch()

    #expect(fixture.clock.isRunning)
    let firstFrame = try #require(window.frame).minX
    #expect(firstFrame < 300 && firstFrame > 200)
    while fixture.clock.isRunning { fixture.clock.tick() }
    #expect(window.frame == ExpectedStrip(columns: [1]).frame(of: 1))
  }

  @Test func speedsUseTheTunedSpringResponses() {
    #expect(AnimationSpeed.fast.springResponse == 0.20)
    #expect(AnimationSpeed.standard.springResponse == 0.30)
    #expect(AnimationSpeed.relaxed.springResponse == 0.42)
    #expect(Preferences().animationSpeed == .fast)
  }

  @Test func theFocusBorderWaitsForTheWindowThenAppearsAtItsTarget() throws {
    let (fixture, row) = try launchedRow(speed: .fast)
    while fixture.clock.isRunning { fixture.clock.tick(by: 1.0 / 120) }

    fixture.manager.perform(.focusLast)
    #expect(fixture.overlays.focusBorder == nil)

    let target = try #require(finalFrames()[3])
    var shownFrames: [CGRect] = []
    while fixture.clock.isRunning {
      fixture.clock.tick(by: 1.0 / 120)
      if let border = fixture.overlays.focusBorder { shownFrames.append(border.frame) }
    }
    #expect(!shownFrames.isEmpty)
    #expect(shownFrames.allSatisfy { $0 == target })
    #expect(fixture.windowShowingFocusBorder(among: row) === row[2])
  }
}
