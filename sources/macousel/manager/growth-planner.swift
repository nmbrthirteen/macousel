import CoreGraphics
import StripCore

struct GrowthPlanner {
  private let gate = GrowthGate()

  func submissions(for planned: [PlannedFrame], holdingGrowth: Bool) -> [FrameSubmission] {
    guard holdingGrowth else {
      return planned.map { FrameSubmission(window: $0.window, frame: $0.target) }
    }
    var frames = Dictionary(
      uniqueKeysWithValues: planned.map { ($0.window, $0.isGrowing ? $0.heldFrame : $0.target) })
    var submissions = planned.filter { !$0.isGrowing }.map {
      FrameSubmission(window: $0.window, frame: $0.target)
    }
    for grower in planned where grower.isGrowing {
      let obstacles = planned.filter { isObstacle($0, to: grower) }.map {
        GrowthGate.Obstacle(frame: frames[$0.window] ?? $0.target, isParked: $0.isParked)
      }
      let frame =
        gate.allowsGrowth(to: grower.target, amid: obstacles) ? grower.target : grower.heldFrame
      frames[grower.window] = frame
      submissions.append(FrameSubmission(window: grower.window, frame: frame))
    }
    return submissions
  }

  private func isObstacle(_ other: PlannedFrame, to grower: PlannedFrame) -> Bool {
    guard other.window != grower.window, !other.placement.isBehindTab else { return false }
    return !(grower.placement.isBehindTab && other.placement.column == grower.placement.column)
  }
}
