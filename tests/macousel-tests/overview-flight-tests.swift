import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewFlightTests {
  private let display = CGRect(x: 0, y: 0, width: 1600, height: 1000)

  @Test func onScreenWindowStartsAtItsRealFrame() {
    let frame = CGRect(x: 200, y: 40, width: 800, height: 900)
    #expect(OverviewFlight.source(of: frame, on: display) == frame)
  }

  @Test func framesOnASecondDisplayAreMeasuredFromThatDisplay() {
    let second = CGRect(x: 1600, y: -200, width: 1200, height: 800)
    let frame = CGRect(x: 1700, y: -150, width: 600, height: 700)
    #expect(
      OverviewFlight.source(of: frame, on: second)
        == CGRect(x: 100, y: 50, width: 600, height: 700))
  }

  @Test func windowParkedPastTheRightEdgeFliesInFromThatEdge() {
    let frame = CGRect(x: 1590, y: 40, width: 800, height: 900)
    #expect(
      OverviewFlight.source(of: frame, on: display)
        == CGRect(x: 1600, y: 40, width: 800, height: 900))
  }

  @Test func windowLaidOutFarLeftFliesInFromTheLeftEdge() {
    let frame = CGRect(x: -3000, y: 40, width: 800, height: 900)
    #expect(
      OverviewFlight.source(of: frame, on: display)
        == CGRect(x: -800, y: 40, width: 800, height: 900))
  }

  @Test func partlyVisibleWindowKeepsItsFrame() {
    let frame = CGRect(x: 1200, y: 40, width: 800, height: 900)
    #expect(OverviewFlight.source(of: frame, on: display) == frame)
  }

  @Test func transformMovesAndScalesTheSlotOntoTheSource() {
    let slot = CGRect(x: 100, y: 100, width: 200, height: 100)
    let source = CGRect(x: 0, y: 0, width: 800, height: 400)

    let transform = OverviewFlight.transform(from: slot, to: source)

    #expect(transform.offset == CGSize(width: 200, height: 50))
    #expect(transform.scale == CGSize(width: 4, height: 4))
    #expect(OverviewFlight.transform(from: slot, to: slot) == .identity)
  }

  @Test func aCardStartsExactlyOnItsRealWindow() {
    let snapshot = OverviewSnapshot(
      columns: [
        OverviewSnapshot.Column(
          width: 800,
          cards: [
            OverviewSnapshot.Card(
              window: WindowID(1), title: "One", bundleIdentifier: nil, heightShare: 1,
              frame: CGRect(x: 1800, y: 40, width: 800, height: 900))
          ])
      ], stripHeight: 900, selection: nil)
    let second = CGRect(x: 1600, y: 0, width: 1600, height: 1000)
    let slot = OverviewGeometry(snapshot: snapshot, size: second.size).cards[0].rect

    let source = OverviewFlight.source(of: CGRect(x: 1800, y: 40, width: 800, height: 900), on: second)
    let start = OverviewFlight.transform(from: slot, to: source).applied(to: slot)

    #expect(start == CGRect(x: 200, y: 40, width: 800, height: 900))
    #expect(slot.width < start.width)
  }

  @Test func theIdentityTransformLeavesTheCardInItsSlot() {
    let slot = CGRect(x: 120, y: 80, width: 300, height: 200)
    #expect(OverviewFlight.Transform.identity.applied(to: slot) == slot)
  }

  @Test func aWindowWithOnlyASliverShowingCountsAsParked() {
    #expect(!OverviewFlight.isShown(CGRect(x: 1590, y: 40, width: 800, height: 900), on: display))
    #expect(OverviewFlight.isShown(CGRect(x: 1200, y: 40, width: 800, height: 900), on: display))
  }
}
