import CoreGraphics

struct LiveDrag {
  enum Kind {
    case move
    case resize
  }

  var window: CGWindowID
  var baseline: CGRect
  var kind: Kind
}
