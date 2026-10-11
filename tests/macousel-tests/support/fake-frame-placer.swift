import CoreGraphics

@testable import Macousel

@MainActor
final class FakeFramePlacer: FramePlacer {
  struct Submission: Equatable {
    var window: CGWindowID
    var frame: CGRect
  }

  var isIdle = true
  private(set) var submissions: [Submission] = []
  private(set) var forgotten: [CGWindowID] = []
  private(set) var flushCount = 0

  func submit(_ frame: CGRect, for window: any WindowHandle) {
    submissions.append(Submission(window: window.id, frame: frame))
    window.setFrame(frame)
  }

  func flush() {
    flushCount += 1
  }

  func forget(_ window: CGWindowID) {
    forgotten.append(window)
  }
}
