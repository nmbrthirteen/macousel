import CoreGraphics

enum SceneWindowStyle: CaseIterable {
  case document, sidebar, console, gallery, chat
}

struct SceneWindow: Identifiable, Equatable {
  let id: Int
  let style: SceneWindowStyle
  var rect: CGRect
  var isFocused: Bool
}

struct SceneCursor: Equatable {
  var point: CGPoint
  var isPressed = false
}

struct SceneMenuState: Equatable {
  var highlighted: Int?
}

struct SceneFrame: Equatable {
  var windows: [SceneWindow]
  var position: StripPosition?
  var keys: String?
  var cursor: SceneCursor?
  var accessToggle: Bool?
  var menu: SceneMenuState?
  var hold: Duration
}
