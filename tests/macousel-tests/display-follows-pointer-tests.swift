import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DisplayFollowsPointerTests {
  private static let settleTime = Duration.milliseconds(300)
  private let pair = [Display.leftOfPair, Display.rightOfPair]
  private let leftPoint = CGPoint(x: 500, y: 400)
  private let rightPoint = CGPoint(x: 1500, y: 400)

  private func launchedPair(
    configure: (inout Preferences) -> Void = { _ in }
  ) throws -> (ControllerFixture, left: [FakeWindow], right: [FakeWindow]) {
    let fixture = try ControllerFixture(displays: pair) {
      $0.layout.defaultWidth = 0.25
      configure(&$0)
    }
    let left = [fixture.open(1, atX: 100, activating: true), fixture.open(2, atX: 400)]
    let right = [fixture.open(3, atX: 1100), fixture.open(4, atX: 1400)]
    fixture.launch()
    return (fixture, left, right)
  }

  @Test func restingOnTheSecondDisplayMakesFocusRightActThere() async throws {
    let (fixture, left, right) = try launchedPair()

    fixture.pointer.moveTo(rightPoint)
    #expect(await fixture.becomes { right[0].focusCount == 1 })
    fixture.manager.perform(.focusRight)

    #expect(right[1].focusCount == 1)
    #expect(left.allSatisfy { $0.focusCount == 0 })
    #expect(fixture.pointer.warps.isEmpty)
  }

  @Test func passingThroughAndReturningBeforeTheDelayChangesNothing() async throws {
    let (fixture, left, right) = try launchedPair()

    fixture.pointer.moveTo(rightPoint)
    fixture.pointer.moveTo(leftPoint)
    try await Task.sleep(for: Self.settleTime)
    fixture.manager.perform(.focusRight)

    #expect(right.allSatisfy { $0.focusCount == 0 })
    #expect(left[1].focusCount == 1)
  }

  @Test func theDisplayIsNotActivatedWhenThePreferenceIsOff() async throws {
    let (fixture, left, right) = try launchedPair { $0.displayFollowsPointer = false }

    fixture.pointer.moveTo(rightPoint)
    try await Task.sleep(for: Self.settleTime)
    fixture.manager.perform(.focusRight)

    #expect(right.allSatisfy { $0.focusCount == 0 })
    #expect(left[1].focusCount == 1)
  }

  @Test func nothingHappensWhileThePrimaryButtonIsDown() async throws {
    let (fixture, _, right) = try launchedPair()
    fixture.pointer.pressPrimary(at: leftPoint)

    fixture.pointer.moveTo(rightPoint)
    try await Task.sleep(for: Self.settleTime)

    #expect(right.allSatisfy { $0.focusCount == 0 })
  }

  @Test func theDisplayDoesNotReactivateUntilThePointerLeavesAndReturns() async throws {
    let (fixture, left, right) = try launchedPair()
    fixture.pointer.moveTo(rightPoint)
    #expect(await fixture.becomes { right[0].focusCount == 1 })
    fixture.manager.perform(.focusLeft)
    #expect(left[0].focusCount == 1)

    fixture.pointer.moveTo(CGPoint(x: 1600, y: 300))
    try await Task.sleep(for: Self.settleTime)

    #expect(right[0].focusCount == 1)
    #expect(left[0].focusCount == 1)
  }

  @Test func anEmptySecondDisplayBecomesActiveAndANewWindowThereTakesFocus() async throws {
    let fixture = try ControllerFixture(displays: pair) { $0.layout.defaultWidth = 0.25 }
    let left = [fixture.open(1, atX: 100, activating: true), fixture.open(2, atX: 400)]
    fixture.launch()

    fixture.pointer.moveTo(rightPoint)
    #expect(await fixture.becomes { fixture.overlays.focusBorder == nil })
    fixture.manager.perform(.focusLeft)
    #expect(left[0].focusCount == 1)

    fixture.pointer.moveTo(CGPoint(x: 1600, y: 300))
    try await Task.sleep(for: Self.settleTime)
    let newcomer = fixture.open(3, atX: 1100, activating: true)
    #expect(await fixture.becomes { fixture.windowShowingFocusBorder(among: [newcomer]) === newcomer })
  }
}
