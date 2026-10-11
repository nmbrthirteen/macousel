import CoreGraphics
import WindowSystem

@MainActor
struct PlacementTrace {
  private(set) var worstOverlap: CGFloat = 0
  private let screen: CGRect
  private var frames: [CGWindowID: CGRect]
  private var consumed: Int

  init(frames: [CGWindowID: CGRect], consumed: Int, on display: Display = .fake()) {
    screen = display.frame
    self.frames = frames
    self.consumed = consumed
  }

  mutating func record(_ submissions: [FakeFramePlacer.Submission]) {
    for submission in submissions[consumed...] {
      frames[submission.window] = submission.frame
    }
    consumed = submissions.count
    worstOverlap = max(worstOverlap, currentWorstOverlap)
  }

  private var currentWorstOverlap: CGFloat {
    let all = frames.values.map { $0.intersection(screen) }.filter { !$0.isNull }
    var worst: CGFloat = 0
    for (index, first) in all.enumerated() {
      for second in all[(index + 1)...] {
        let horizontal = min(first.maxX, second.maxX) - max(first.minX, second.minX)
        let vertical = min(first.maxY, second.maxY) - max(first.minY, second.minY)
        if horizontal > 0 && vertical > 0 { worst = max(worst, min(horizontal, vertical)) }
      }
    }
    return worst
  }
}
