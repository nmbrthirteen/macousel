import CoreGraphics

struct DragCandidate {
  var window: CGWindowID
  var requested: CGRect
  var baseline: CGRect
}
