import CoreGraphics
import Dispatch
import WindowSystem

final class SystemFramePlacer: FramePlacer {
  var onSlowAppChange: ((_ bundleIdentifier: String, _ isSlow: Bool) -> Void)?

  private let applier = FrameApplier()
  private let tracker: WindowTracker

  init(tracker: WindowTracker) {
    self.tracker = tracker
    applier.observeSlowChanges { [weak self] bundleIdentifier, isSlow in
      DispatchQueue.main.async {
        MainActor.assumeIsolated { self?.onSlowAppChange?(bundleIdentifier, isSlow) }
      }
    }
  }

  var isIdle: Bool { applier.isIdle }

  func isSlowApp(of window: any WindowHandle) -> Bool {
    applier.isSlow(pid: window.pid, bundleIdentifier: window.bundleIdentifier)
  }

  func seedSlowApps(_ bundleIdentifiers: Set<String>) {
    applier.seedSlowApps(bundleIdentifiers)
  }

  func submit(_ frame: CGRect, for window: any WindowHandle) {
    guard let managed = tracker.windows[window.id] else { return }
    applier.submit(frame, for: managed)
  }

  func afterPlacement(
    of window: any WindowHandle, within timeout: Duration, _ action: @escaping () -> Void
  ) {
    guard let managed = tracker.windows[window.id] else {
      action()
      return
    }
    applier.afterPlacement(of: managed, within: timeout, action)
  }

  func flush() {
    applier.flush()
  }

  func forget(_ window: CGWindowID) {
    applier.forget(window)
  }
}
