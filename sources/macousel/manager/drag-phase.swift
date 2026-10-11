import CoreGraphics

enum DragPhase {
  case idle
  case candidate(DragCandidate)
  case live(LiveDrag)
  case cancelled(CGWindowID)
}
