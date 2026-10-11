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

  @discardableResult
  func noteTimeout(of window: any WindowHandle) -> Bool {
    guard window.consumeReadTimeout() else { return false }
    pausedUntil[window.pid] = now().advanced(by: Self.readPause)
    return true
  }

  func pruneExpired() {
    pausedUntil = pausedUntil.filter { $0.value > now() }
  }
}
