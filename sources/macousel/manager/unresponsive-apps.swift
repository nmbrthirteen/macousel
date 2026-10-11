import CoreGraphics

final class UnresponsiveApps {
  private static let readPause = Duration.seconds(2)

  private let now: () -> ContinuousClock.Instant
  private var pausedUntil: [pid_t: ContinuousClock.Instant] = [:]

  init(now: @escaping () -> ContinuousClock.Instant) {
    self.now = now
  }

  func isPaused(_ pid: pid_t) -> Bool {
    guard let until = pausedUntil[pid] else { return false }
    if now() < until { return true }
    pausedUntil[pid] = nil
    return false
  }

  func noteTimeout(ofApp pid: pid_t) {
    pausedUntil[pid] = now().advanced(by: Self.readPause)
  }

  func pruneExpired() {
    pausedUntil = pausedUntil.filter { $0.value > now() }
  }
}
