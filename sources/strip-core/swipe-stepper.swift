public struct SwipeStepper: Sendable, Equatable {
  public static let firstStepShare = 0.06
  public static let nextStepShare = 0.24

  private var travel = 0.0
  private var anchor = 0.0
  private var hasStepped = false

  public init() {}

  public mutating func advance(by share: Double) -> Int {
    travel += share
    var steps = 0
    while abs(travel - anchor) >= threshold {
      let direction = travel > anchor ? 1 : -1
      anchor += Double(direction) * threshold
      hasStepped = true
      steps += direction
    }
    return steps
  }

  private var threshold: Double {
    hasStepped ? Self.nextStepShare : Self.firstStepShare
  }
}
