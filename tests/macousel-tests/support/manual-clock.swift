@testable import Macousel

@MainActor
final class ManualClock: AnimationClock {
  var onFrame: ((_ deltaTime: Double) -> Void)?
  var frameInterval = 1.0 / 120
  private(set) var now = ContinuousClock.now
  private(set) var isRunning = false
  private(set) var startCount = 0

  func start() {
    guard !isRunning else { return }
    isRunning = true
    startCount += 1
  }

  func stop() {
    isRunning = false
  }

  func advance(by duration: Duration) {
    now = now.advanced(by: duration)
  }

  func tick(by deltaTime: Double = 1.0 / 60) {
    guard isRunning else { return }
    onFrame?(deltaTime)
  }
}
