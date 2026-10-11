import CoreGraphics
import StripCore

enum MinimapInteraction {
  struct Drag {
    var window: WindowID
    var cell: WindowID
    var grab: CGVector
    var target: DropTarget
  }

  case idle
  case pressed(window: WindowID, origin: CGPoint)
  case dragging(Drag)
}
