struct EngineAppCycler {
  enum Choice: Equatable {
    case focusColumn(Int)
    case activateApp
  }

  static func choice(bundleIdentifier: String, in snapshot: EngineSnapshot?) -> Choice {
    guard let snapshot else { return .activateApp }
    let columns = snapshot.tiledColumns.columns
    let matching = columns.indices.filter { index in
      columns[index].windows.contains { $0.bundleId == bundleIdentifier }
    }
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
