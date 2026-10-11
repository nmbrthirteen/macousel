import Observation

@Observable
final class SwipeDemo {
  private(set) var progress = 0.0
  @ObservationIgnored private let sleep: PreviewSleep
  @ObservationIgnored private var task: Task<Void, Never>?

  init(sleep: @escaping PreviewSleep = PreviewClock.live) {
    self.sleep = sleep
  }

  func replay(after delay: Duration, reduceMotion: Bool) {
    stop()
    if reduceMotion {
      progress = 1
      return
    }
    task = Task { [self] in
      do {
        try await sleep(delay)
        await play()
      } catch {
        return
      }
    }
  }

  func stop() {
    task?.cancel()
    task = nil
    progress = 0
  }

  func play() async {
    do {
      progress = 0
      try await sleep(PreviewMetrics.Timing.swipeRestPause)
      progress = 1
      try await sleep(PreviewMetrics.Timing.swipeHold)
      progress = 0
    } catch {
      return
    }
  }
}
