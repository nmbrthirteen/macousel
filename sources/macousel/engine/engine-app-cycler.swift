struct EngineAppCycler {
  enum Choice: Equatable {
    case focusColumn(Int)
    case activateApp
  }

  static func choice(bundleIdentifier: String, in snapshot: EngineSnapshot?) -> Choice {
    guard let snapshot else { return .activateApp }
    let matching = snapshot.tiledWindows.enumerated().filter {
      $0.element.bundleId == bundleIdentifier
    }.map(\.offset)
    guard let first = matching.first else { return .activateApp }
    let focused = snapshot.focusedColumnIndex
    let next: Int
    if let current = matching.firstIndex(where: { $0 == focused }) {
      next = matching[(current + 1) % matching.count]
    } else {
      next = first
    }
    return .focusColumn(next + 1)
  }
}
