import StripCore
import WindowSystem

struct Workspace {
  struct Key: Hashable {
    var displayUUID: String
    var space: UInt64
  }

  var strip = Strip()
  var motion = MotionField()
  var gestureOffset: Double?

  var scrollOffset: Double { gestureOffset ?? strip.scrollOffset }
}

extension Workspace.Key {
  init(currentSpaceOf display: Display) {
    self.init(displayUUID: display.uuid, space: Spaces.currentSpace(of: display))
  }
}

extension WindowID {
  init(_ window: ManagedWindow) {
    self.init(window.id)
  }
}
