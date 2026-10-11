struct EngineRestartPolicy {
  enum Decision: Equatable {
    case restart(after: Duration)
    case giveUp
  }

  static let window = Duration.seconds(60)
  static let maximumRestarts = 3
  static let backoff: [Duration] = [.seconds(1), .seconds(2), .seconds(4)]

  private(set) var restarts: [ContinuousClock.Instant] = []

  mutating func decide(at now: ContinuousClock.Instant) -> Decision {
    restarts = restarts.filter { now - $0 < Self.window }
    guard restarts.count < Self.maximumRestarts else { return .giveUp }
    let delay = Self.backoff[min(restarts.count, Self.backoff.count - 1)]
    restarts.append(now)
    return .restart(after: delay)
  }

  mutating func reset() {
    restarts = []
  }
}
