final class AccessibilityMonitor {
  struct Intervals {
    var whileWaiting: Duration
    var whileWatching: Duration

    static let standard = Intervals(whileWaiting: .seconds(1), whileWatching: .seconds(2))
  }

  private let environment: any DesktopEnvironment
  private let intervals: Intervals
  private var task: Task<Void, Never>?

  init(environment: any DesktopEnvironment, intervals: Intervals) {
    self.environment = environment
    self.intervals = intervals
  }

  func waitForGrant(then granted: @escaping () -> Void) {
    task?.cancel()
    task = Task {
      while !environment.isAccessibilityGranted {
        try? await Task.sleep(for: intervals.whileWaiting)
        if Task.isCancelled { return }
      }
      granted()
    }
  }

  func watchForLoss(then lost: @escaping () -> Void) {
    task?.cancel()
    task = Task {
      while environment.isAccessibilityGranted {
        try? await Task.sleep(for: intervals.whileWatching)
        if Task.isCancelled { return }
      }
      lost()
    }
  }

  func stop() {
    task?.cancel()
    task = nil
  }
}
