import CoreGraphics
import WindowSystem

final class SystemFramePlacer: FramePlacer {
  private let applier = FrameApplier()
  private let tracker: WindowTracker

  init(tracker: WindowTracker) {
    self.tracker = tracker
  }

  var isIdle: Bool { applier.isIdle }

  func submit(_ frame: CGRect, for window: any WindowHandle) {
    guard let managed = tracker.windows[window.id] else { return }
    applier.submit(frame, for: managed)
  }

  func flush() {
    applier.flush()
  }

  func forget(_ window: CGWindowID) {
    applier.forget(window)
  }
}
