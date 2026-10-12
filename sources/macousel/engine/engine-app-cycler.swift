import StripCore

struct EngineAppCycler {
  enum Choice: Equatable {
    case focusWindow(WindowID)
    case activateApp
  }

  static func choice(bundleIdentifier: String, in snapshot: EngineSnapshot?) -> Choice {
    guard let snapshot else { return .activateApp }
    let matching = snapshot.tiledColumns.columns.flatMap(\.windows)
      .filter { $0.bundleId == bundleIdentifier }
      .compactMap { EngineWindowID.make($0.windowId) }
    guard let first = matching.first else { return .activateApp }
    guard let current = matching.firstIndex(where: { $0 == snapshot.focusedWindowID }) else {
      return .focusWindow(first)
    }
    return .focusWindow(matching[(current + 1) % matching.count])
  }
}
