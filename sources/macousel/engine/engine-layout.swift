nonisolated struct EngineLayout: Decodable, Equatable, Sendable {
  struct Window: Decodable, Equatable, Sendable {
    var id: Int32
  }

  struct Column: Decodable, Equatable, Sendable {
    var windows: [Window]
  }

  struct Workspace: Decodable, Equatable, Sendable {
    var active: Bool
    var columns: [Column]
  }

  struct Display: Decodable, Equatable, Sendable {
    var id: UInt32
    var workspaces: [Workspace]
  }

  var displays: [Display]

  func columns(onDisplay display: UInt32?) -> [[Int32]] {
    let shown = displays.filter { display == nil || $0.id == display }
    let active = shown.flatMap(\.workspaces).filter(\.active)
    return active.flatMap(\.columns).map { $0.windows.map(\.id) }
  }
}
