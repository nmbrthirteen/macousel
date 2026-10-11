import CoreGraphics

@testable import Macousel

@MainActor
final class FakeFramePlacer: FramePlacer {
  struct Submission: Equatable {
    var window: CGWindowID
    var frame: CGRect
  }

  var isIdle = true
  private var slowApps: Set<pid_t> = []
  private(set) var submissions: [Submission] = []
  private(set) var forgotten: [CGWindowID] = []
  private(set) var flushCount = 0

  func submit(_ frame: CGRect, for window: any WindowHandle) {
    submissions.append(Submission(window: window.id, frame: frame))
    window.setFrame(frame)
  }

  func isSlowApp(of window: any WindowHandle) -> Bool {
    slowApps.contains(window.pid)
  }

  func setSlow(_ isSlow: Bool, forAppOf window: any WindowHandle) {
    if isSlow {
      slowApps.insert(window.pid)
    } else {
      slowApps.remove(window.pid)
    }
  }

  func flush() {
    flushCount += 1
  }

  func forget(_ window: CGWindowID) {
    forgotten.append(window)
  }
}
