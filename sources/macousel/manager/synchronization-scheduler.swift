final class SynchronizationScheduler {
  static let standardDelays: [Duration] = [.milliseconds(60), .milliseconds(340)]
  static let creationDelays: [Duration] = [.zero, .milliseconds(400)]

  var onSynchronize: (() -> Void)?
  private var task: Task<Void, Never>?

  func schedule(delays: [Duration] = SynchronizationScheduler.standardDelays) {
    task?.cancel()
    task = Task {
      for delay in delays {
        if delay > .zero { try? await Task.sleep(for: delay) }
        if Task.isCancelled { return }
        onSynchronize?()
      }
    }
  }

  func cancel() {
    task?.cancel()
    task = nil
  }
}
