import CoreGraphics
import Foundation
import Testing

@testable import WindowSystem

struct TapEventPolicyTests {
  private let gesture: Hotkey.Modifiers = [.control, .option]
  private let gestureFlags: CGEventFlags = [.maskControl, .maskAlternate]
  private let beganPhase: Int64 = 1
  private let changedPhase: Int64 = 2

  private func scroll(
    flags: CGEventFlags, momentum: Int64 = 0, phase: Int64 = 2, horizontal: Double = 12,
    vertical: Double = 0
  ) -> TapInput {
    .scroll(
      flags: flags, momentumPhase: momentum, scrollPhase: phase, horizontalDelta: horizontal,
      verticalDelta: vertical)
  }

  private func mouse(
    _ kind: TapMouseEvent.Kind, at timestamp: TimeInterval, x: Double = 10
  ) -> TapInput {
    .mouse(kind: kind, location: CGPoint(x: x, y: 20), timestamp: timestamp)
  }

  @Test func scrollWithTheGestureModifiersIsSwallowedAndForwarded() {
    var policy = TapEventPolicy()

    let verdict = policy.verdict(
      for: scroll(flags: gestureFlags, phase: beganPhase), scrollModifiers: gesture)

    #expect(verdict.swallows)
    #expect(verdict.delivery == .scroll(deltaX: 12, phase: .began))
  }

  @Test func scrollWithoutTheModifiersPassesThroughUntouched() {
    var policy = TapEventPolicy()

    let verdict = policy.verdict(for: scroll(flags: []), scrollModifiers: gesture)

    #expect(verdict == .ignored)
  }

  @Test func scrollWithExtraModifiersPassesThrough() {
    var policy = TapEventPolicy()

    let verdict = policy.verdict(
      for: scroll(flags: [.maskControl, .maskAlternate, .maskShift]), scrollModifiers: gesture)

    #expect(verdict == .ignored)
  }

  @Test func scrollPassesThroughWhenTheGestureIsDisabled() {
    var policy = TapEventPolicy()

    let verdict = policy.verdict(for: scroll(flags: gestureFlags), scrollModifiers: [])

    #expect(verdict == .ignored)
  }

  @Test func momentumScrollWithTheModifiersIsSwallowedButNotForwarded() {
    var policy = TapEventPolicy()

    let verdict = policy.verdict(
      for: scroll(flags: gestureFlags, momentum: 2), scrollModifiers: gesture)

    #expect(verdict == TapVerdict(swallows: true, delivery: nil))
  }

  @Test(arguments: [TapMouseEvent.Kind.pressed, .dragged, .released])
  func everyMouseEventPassesThroughAndIsForwarded(kind: TapMouseEvent.Kind) {
    var policy = TapEventPolicy()

    let verdict = policy.verdict(for: mouse(kind, at: 1), scrollModifiers: gesture)

    #expect(!verdict.swallows)
    #expect(verdict.delivery == TapDelivery.mouse(TapMouseEvent(kind: kind, location: CGPoint(x: 10, y: 20))))
  }

  @Test func mouseEventsPassThroughEvenWithTheScrollGestureEnabled() {
    var policy = TapEventPolicy()

    let kinds: [TapMouseEvent.Kind] = [.pressed, .dragged, .released]
    var verdicts: [TapVerdict] = []
    for (index, kind) in kinds.enumerated() {
      verdicts.append(policy.verdict(for: mouse(kind, at: Double(index)), scrollModifiers: gesture))
    }

    #expect(verdicts.allSatisfy { !$0.swallows })
  }

  @Test func draggedEventsCloserThanASixtiethOfASecondAreDropped() {
    var policy = TapEventPolicy()
    let first = policy.verdict(for: mouse(.dragged, at: 1.000), scrollModifiers: gesture)

    let second = policy.verdict(for: mouse(.dragged, at: 1.008), scrollModifiers: gesture)
    let third = policy.verdict(for: mouse(.dragged, at: 1.017), scrollModifiers: gesture)
    let fourth = policy.verdict(for: mouse(.dragged, at: 1.025), scrollModifiers: gesture)

    #expect(first.delivery != nil)
    #expect(second == .ignored)
    #expect(third.delivery != nil)
    #expect(fourth == .ignored)
  }

  @Test func aPressOrReleaseIsNeverThrottled() {
    var policy = TapEventPolicy()
    _ = policy.verdict(for: mouse(.dragged, at: 1.000), scrollModifiers: gesture)

    let released = policy.verdict(for: mouse(.released, at: 1.001), scrollModifiers: gesture)
    let pressed = policy.verdict(for: mouse(.pressed, at: 1.002), scrollModifiers: gesture)

    #expect(released.delivery != nil)
    #expect(pressed.delivery != nil)
  }

  @Test func theFirstDraggedEventAfterAPressIsDelivered() {
    var policy = TapEventPolicy()
    _ = policy.verdict(for: mouse(.dragged, at: 1.000), scrollModifiers: gesture)
    _ = policy.verdict(for: mouse(.released, at: 1.002), scrollModifiers: gesture)
    _ = policy.verdict(for: mouse(.pressed, at: 1.003), scrollModifiers: gesture)

    let dragged = policy.verdict(for: mouse(.dragged, at: 1.004), scrollModifiers: gesture)

    #expect(dragged.delivery != nil)
  }
}
