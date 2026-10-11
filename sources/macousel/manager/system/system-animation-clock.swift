import WindowSystem

final class SystemAnimationClock: AnimationClock {
  private let ticker = FrameTicker()

  var onFrame: ((_ deltaTime: Double) -> Void)? {
    get { ticker.onFrame }
    set { ticker.onFrame = newValue }
  }

  var isRunning: Bool { ticker.isRunning }

  var frameInterval: Double { ticker.frameInterval }

  var now: ContinuousClock.Instant { .now }

  func start() {
    ticker.start()
  }

  func stop() {
    ticker.stop()
  }

  func schedule(after delay: Duration, _ action: @escaping () -> Void) {
    Task {
      try? await Task.sleep(for: delay)
      action()
    }
  }
}
