import CoreGraphics

struct SlowSubmissionLimiter {
  static let trackingInterval = Duration.milliseconds(100)

  private var isTracking = false
  private var lastSubmitted: [CGWindowID: ContinuousClock.Instant] = [:]

  mutating func beginTracking() {
    isTracking = true
  }

  mutating func endTracking() {
    isTracking = false
  }

  func permits(_ window: CGWindowID, at now: ContinuousClock.Instant) -> Bool {
    guard isTracking, let last = lastSubmitted[window] else { return true }
    return last.duration(to: now) >= Self.trackingInterval
  }

  mutating func record(_ window: CGWindowID, at now: ContinuousClock.Instant) {
    lastSubmitted[window] = now
  }

  mutating func retain(only alive: Set<CGWindowID>) {
    lastSubmitted = lastSubmitted.filter { alive.contains($0.key) }
  }
}
