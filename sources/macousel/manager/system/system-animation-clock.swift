import WindowSystem

final class SystemAnimationClock: AnimationClock {
  private let ticker = FrameTicker()

  var onFrame: ((_ deltaTime: Double) -> Void)? {
    get { ticker.onFrame }
    set { ticker.onFrame = newValue }
  }

  var isRunning: Bool { ticker.isRunning }

  func start() {
    ticker.start()
  }

  func stop() {
    ticker.stop()
  }
}
