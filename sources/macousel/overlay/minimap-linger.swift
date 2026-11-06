// A scroll or swipe restarts the linger on every event, so a restart only moves the
// deadline. The single pending timer re-arms itself for the remainder when it fires early.
final class MinimapLinger {
  var onElapsed: () -> Void = {}

  private let now: () -> ContinuousClock.Instant
  private let schedule: (Duration, @escaping () -> Void) -> Void
  private var deadline: ContinuousClock.Instant?
  private var isTimerPending = false

  init(
    now: @escaping () -> ContinuousClock.Instant,
    schedule: @escaping (Duration, @escaping () -> Void) -> Void
  ) {
    self.now = now
    self.schedule = schedule
  }

  var isRunning: Bool { deadline != nil }

  func restart(after delay: Duration) {
    deadline = now().advanced(by: delay)
    guard !isTimerPending else { return }
    arm(after: delay)
  }

  func cancel() {
    deadline = nil
  }

  private func arm(after delay: Duration) {
    isTimerPending = true
    schedule(delay) { [weak self] in self?.fired() }
  }

  private func fired() {
    isTimerPending = false
    guard let deadline else { return }
    let remaining = now().duration(to: deadline)
    guard remaining <= .zero else {
      arm(after: remaining)
      return
    }
    self.deadline = nil
    onElapsed()
  }
}
