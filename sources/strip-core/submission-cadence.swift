public struct SubmissionCadence: Sendable, Equatable {
  static let halvingRatio = 0.6
  static let quarteringRatio = 1.2
  static let recoveryRatio = 0.5

  public private(set) var divisor = 1

  public init() {}

  @discardableResult
  public mutating func update(frameInterval: Double, slowestAverage: Double) -> Int {
    guard frameInterval > 0 else { return divisor }
    let ratio = slowestAverage / frameInterval
    if ratio > Self.quarteringRatio {
      divisor = 4
    } else if ratio > Self.halvingRatio {
      divisor = 2
    } else if ratio < Self.recoveryRatio {
      divisor = 1
    }
    return divisor
  }
}
