import CoreGraphics

struct ScenePose: Equatable {
  var windows: [SceneWindow]
  var position: StripPosition?
  var keys: String?
  var keysVisibility = 0.0
  var cursor: CGPoint?
  var cursorVisibility = 0.0
  var press = 0.0
  var card = 0.0
  var toggle = 0.0
  var menu = 0.0
  var menuHighlight: Int?
  var stage = 1.0

  init(_ frame: SceneFrame) {
    windows = frame.windows
    position = frame.position
    keys = frame.keys
    keysVisibility = frame.keys == nil ? 0 : 1
    cursor = frame.cursor?.point
    cursorVisibility = frame.cursor == nil ? 0 : 1
    press = frame.cursor?.isPressed == true ? 1 : 0
    card = frame.accessToggle == nil ? 0 : 1
    toggle = frame.accessToggle == true ? 1 : 0
    menu = frame.menu == nil ? 0 : 1
    menuHighlight = frame.menu?.highlighted
  }

  func moving(toward frame: SceneFrame, by progress: Double) -> ScenePose {
    var pose = self
    pose.windows = frame.windows.map { window in
      var moved = window
      if let start = windows.first(where: { $0.id == window.id }) {
        moved.rect = start.rect.mixed(with: window.rect, by: progress)
      }
      return moved
    }
    pose.position = frame.position
    if let target = frame.keys {
      pose.keysVisibility = (keys == target ? keysVisibility : 0).mixed(with: 1, by: progress)
      pose.keys = target
    } else {
      pose.keysVisibility = keysVisibility.mixed(with: 0, by: progress)
    }
    if let target = frame.cursor {
      pose.cursor = (cursor ?? target.point).mixed(with: target.point, by: progress)
      pose.cursorVisibility = cursorVisibility.mixed(with: 1, by: progress)
      pose.press = press.mixed(with: target.isPressed ? 1 : 0, by: progress)
    } else {
      pose.cursorVisibility = cursorVisibility.mixed(with: 0, by: progress)
      pose.press = press.mixed(with: 0, by: progress)
    }
    pose.card = card.mixed(with: frame.accessToggle == nil ? 0 : 1, by: progress)
    pose.menu = menu.mixed(with: frame.menu == nil ? 0 : 1, by: progress)
    if let state = frame.menu {
      pose.menuHighlight = state.highlighted
    }
    if let isOn = frame.accessToggle {
      pose.toggle = toggle.mixed(with: isOn ? 1 : 0, by: progress)
    }
    return pose
  }
}

extension BinaryFloatingPoint {
  func mixed(with other: Self, by progress: Double) -> Self {
    self + (other - self) * Self(progress)
  }
}

extension CGPoint {
  func mixed(with other: CGPoint, by progress: Double) -> CGPoint {
    CGPoint(x: x.mixed(with: other.x, by: progress), y: y.mixed(with: other.y, by: progress))
  }
}

extension CGRect {
  func mixed(with other: CGRect, by progress: Double) -> CGRect {
    CGRect(
      origin: origin.mixed(with: other.origin, by: progress),
      size: CGSize(
        width: width.mixed(with: other.width, by: progress),
        height: height.mixed(with: other.height, by: progress)))
  }
}
