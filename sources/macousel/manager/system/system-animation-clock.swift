import Foundation
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

  // The drag poller calls this every frame, so it avoids allocating a Task per tick.
  func schedule(after delay: Duration, _ action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay.timeInterval) {
      MainActor.assumeIsolated(action)
    }
  }
}
