import StripCore

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

extension WindowID {
  init(_ window: any WindowHandle) {
    self.init(window.id)
  }
}
