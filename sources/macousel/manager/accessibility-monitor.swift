final class AccessibilityMonitor {
  private let environment: any DesktopEnvironment
  private var task: Task<Void, Never>?

  init(environment: any DesktopEnvironment) {
    self.environment = environment
  }

  func waitForGrant(then granted: @escaping () -> Void) {
    watch(until: true, then: granted)
  }

  func watchForLoss(then lost: @escaping () -> Void) {
    watch(until: false, then: lost)
  }

  func stop() {
    task?.cancel()
    task = nil
    environment.onAccessibilityChanged = nil
  }

  // The callback runs on a later turn so it never re-enters the engine method that armed it.
  private func watch(until granted: Bool, then action: @escaping () -> Void) {
    stop()
    let check = { [weak self, environment] in
      guard let self, self.task == nil, environment.isAccessibilityGranted == granted
      else { return }
      environment.onAccessibilityChanged = nil
      self.task = Task {
        if Task.isCancelled { return }
        action()
      }
    }
    environment.onAccessibilityChanged = check
    check()
  }
}
