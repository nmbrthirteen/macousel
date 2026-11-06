import CoreGraphics
import Testing

@testable import Macousel

@MainActor
struct FloatingRecoveryTests {
  private let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
  private let visible = CGRect(x: 0, y: 25, width: 1000, height: 775)

  @Test func aWindowMostlyOnScreenStaysWhereItIs() {
    let frame = CGRect(x: 700, y: 100, width: 400, height: 300)

    #expect(FloatingRecovery.frame(for: frame, displays: [screen], into: visible) == nil)
  }

  @Test func aWindowMostlyOffTheRightEdgeComesBackFlushWithIt() {
    let frame = CGRect(x: 900, y: 100, width: 400, height: 300)

    #expect(
      FloatingRecovery.frame(for: frame, displays: [screen], into: visible)
        == CGRect(x: 600, y: 100, width: 400, height: 300))
  }

  @Test func aWindowFarOffScreenKeepsItsSizeAndLandsInsideTheVisibleFrame() {
    let frame = CGRect(x: -5000, y: 3000, width: 400, height: 300)

    #expect(
      FloatingRecovery.frame(for: frame, displays: [screen], into: visible)
        == CGRect(x: 0, y: 500, width: 400, height: 300))
  }

  @Test func aWindowUnderTheMenuBarMovesBelowIt() {
    let frame = CGRect(x: 100, y: -290, width: 400, height: 300)

    #expect(
      FloatingRecovery.frame(for: frame, displays: [screen], into: visible)?.origin
        == CGPoint(x: 100, y: 25))
  }

  @Test func aWindowLargerThanTheVisibleFrameLinesUpWithItsTopLeft() {
    let frame = CGRect(x: 2000, y: 0, width: 1200, height: 900)

    #expect(
      FloatingRecovery.frame(for: frame, displays: [screen], into: visible)
        == CGRect(x: 0, y: 25, width: 1200, height: 900))
  }

  @Test func aWindowShownOnAnotherDisplayStaysThere() {
    let second = CGRect(x: 1000, y: 0, width: 1000, height: 800)
    let frame = CGRect(x: 1200, y: 100, width: 400, height: 300)

    #expect(FloatingRecovery.frame(for: frame, displays: [screen, second], into: visible) == nil)
  }

  @Test func aWindowWithNoAreaIsLeftAlone() {
    let frame = CGRect(x: 5000, y: 0, width: 0, height: 300)

    #expect(FloatingRecovery.frame(for: frame, displays: [screen], into: visible) == nil)
  }
}
