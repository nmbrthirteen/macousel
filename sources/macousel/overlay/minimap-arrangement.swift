import StripCore

struct MinimapArrangement {
  let snapshot: MinimapSnapshot

  func applying(_ target: DropTarget, moving window: WindowID) -> MinimapSnapshot {
    guard target != .nowhere else { return snapshot }
    let strip = DropRule.applying(target, moving: window, to: snapshot.makeStrip())
    return snapshot.rearranged(as: strip)
  }
}
