@testable import Macousel

@MainActor
final class ManualClock: AnimationClock {
  var onFrame: ((_ deltaTime: Double) -> Void)?
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

  func tick(by deltaTime: Double = 1.0 / 60) {
    guard isRunning else { return }
    onFrame?(deltaTime)
  }
}
