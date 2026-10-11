@testable import Macousel

@MainActor
final class ManualClock: AnimationClock {
  var onFrame: ((_ deltaTime: Double) -> Void)?
  var frameInterval = 1.0 / 120
  private(set) var now = ContinuousClock.now
  private(set) var isRunning = false
  private(set) var startCount = 0
  var pendingScheduleCount: Int { scheduled.count }
  private var scheduled: [(due: ContinuousClock.Instant, action: () -> Void)] = []

  func start() {
    guard !isRunning else { return }
    isRunning = true
    startCount += 1
  }

  func stop() {
    isRunning = false
  }

  func schedule(after delay: Duration, _ action: @escaping () -> Void) {
    scheduled.append((due: now.advanced(by: delay), action: action))
  }

  func advance(by duration: Duration) {
    now = now.advanced(by: duration)
    let due = scheduled.filter { $0.due <= now }
    scheduled.removeAll { $0.due <= now }
    for entry in due { entry.action() }
  }

  func tick(by deltaTime: Double = 1.0 / 60) {
    guard isRunning else { return }
    onFrame?(deltaTime)
  }
}
