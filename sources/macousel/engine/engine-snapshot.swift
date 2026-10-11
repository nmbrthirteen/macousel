import Foundation

nonisolated struct EngineSnapshot: Decodable, Equatable, Sendable {
  var version: Int
  var timestamp: Int?
  var active: EngineActive
  var virtualWorkspaces: [EngineWorkspace]

  static func decode(_ text: String) -> EngineSnapshot? {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try? decoder.decode(EngineSnapshot.self, from: Data(text.utf8))
  }

  var visibleWindows: [EngineWindow] {
    let activeWorkspaces = virtualWorkspaces.filter(\.active)
    let windows = activeWorkspaces.flatMap(\.windows)
    guard let display = active.displayId else { return windows }
    return windows.filter { $0.displayId == nil || $0.displayId == display }
  }

  var tiledWindows: [EngineWindow] {
    visibleWindows.filter { !$0.floating }
  }

  var focusedColumnIndex: Int? {
    let tiled = tiledWindows
    return tiled.firstIndex { $0.focused } ?? tiled.firstIndex { $0.windowId == active.focusedWindowId }
  }
}
