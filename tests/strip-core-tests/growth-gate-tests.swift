import CoreGraphics
import Testing

@testable import StripCore

struct GrowthGateTests {
  private let gate = GrowthGate()
  private let candidate = CGRect(x: 100, y: 100, width: 400, height: 300)

  private func obstacle(_ frame: CGRect, parked: Bool = false) -> GrowthGate.Obstacle {
    GrowthGate.Obstacle(frame: frame, isParked: parked)
  }

  @Test func freeSpaceAllowsGrowth() {
    let far = obstacle(CGRect(x: 700, y: 100, width: 400, height: 300))

    #expect(gate.allowsGrowth(to: candidate, amid: [far]))
    #expect(gate.allowsGrowth(to: candidate, amid: []))
  }

  @Test func anOverlappingNeighbourHoldsGrowth() {
    let neighbour = obstacle(CGRect(x: 400, y: 100, width: 400, height: 300))

    #expect(!gate.allowsGrowth(to: candidate, amid: [neighbour]))
  }

  @Test func oneOverlappingNeighbourAmongSeveralHoldsGrowth() {
    let clear = obstacle(CGRect(x: 900, y: 100, width: 400, height: 300))
    let blocking = obstacle(CGRect(x: 450, y: 250, width: 100, height: 100))

    #expect(!gate.allowsGrowth(to: candidate, amid: [clear, blocking]))
  }

  @Test func aNeighbourOverlappingByExactlyTheToleranceAllows() {
    let edge = candidate.maxX - GrowthGate.overlapTolerance
    let touching = obstacle(CGRect(x: edge, y: 100, width: 400, height: 300))

    #expect(gate.allowsGrowth(to: candidate, amid: [touching]))
  }

  @Test func aNeighbourOverlappingByMoreThanTheToleranceHolds() {
    let edge = candidate.maxX - GrowthGate.overlapTolerance - 0.5
    let overlapping = obstacle(CGRect(x: edge, y: 100, width: 400, height: 300))

    #expect(!gate.allowsGrowth(to: candidate, amid: [overlapping]))
  }

  @Test func aNeighbourThatOnlyTouchesTheEdgeAllows() {
    let touching = obstacle(CGRect(x: candidate.maxX, y: 100, width: 400, height: 300))

    #expect(gate.allowsGrowth(to: candidate, amid: [touching]))
  }

  @Test func parkedWindowsAreNotObstacles() {
    let parked = obstacle(CGRect(x: 100, y: 100, width: 400, height: 300), parked: true)

    #expect(gate.allowsGrowth(to: candidate, amid: [parked]))
  }

  @Test func overlapOnTheHorizontalAxisOnlyAllows() {
    let below = obstacle(CGRect(x: 100, y: candidate.maxY + 10, width: 400, height: 300))

    #expect(gate.allowsGrowth(to: candidate, amid: [below]))
  }

  @Test func overlapOnTheVerticalAxisOnlyAllows() {
    let beside = obstacle(CGRect(x: candidate.maxX + 10, y: 100, width: 400, height: 300))

    #expect(gate.allowsGrowth(to: candidate, amid: [beside]))
  }

  @Test func overlapBeyondTheToleranceOnOneAxisAndWithinItOnTheOtherAllows() {
    let corner = obstacle(
      CGRect(
        x: candidate.maxX - 50, y: candidate.maxY - GrowthGate.overlapTolerance, width: 400,
        height: 300))

    #expect(gate.allowsGrowth(to: candidate, amid: [corner]))
  }
}
