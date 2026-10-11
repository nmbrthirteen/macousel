import CoreGraphics

enum PrimaryButtonEvent: Equatable {
  case pressed(at: CGPoint)
  case dragged
  case released
}
