import CoreGraphics
import StripCore

struct DropPlan {
  var target: DropTarget
  var destination: Workspace.Key
  var strips: [Workspace.Key: Strip]
  var movesToAnotherDisplay: Bool
  var previewFrame: CGRect?

  var changesLayout: Bool { target != .nowhere || movesToAnotherDisplay }
}
