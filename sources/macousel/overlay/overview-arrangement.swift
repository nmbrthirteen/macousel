import StripCore

struct OverviewArrangement {
  let snapshot: OverviewSnapshot

  func applying(_ target: DropTarget, moving window: WindowID) -> OverviewSnapshot {
    guard target != .nowhere else { return snapshot }
    let strip = DropRule.applying(target, moving: window, to: snapshot.makeStrip())
    return snapshot.rearranged(as: strip)
  }
}
