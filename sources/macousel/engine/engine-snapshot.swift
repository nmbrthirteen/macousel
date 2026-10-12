import Foundation
import StripCore

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

  var tiledColumns: EngineColumns {
    EngineColumns(tiledWindows)
  }

  var focusedWindow: EngineWindow? {
    let tiled = tiledWindows
    return tiled.first { $0.focused } ?? tiled.first { $0.windowId == active.focusedWindowId }
  }

  var focusedWindowID: WindowID? {
    focusedWindow.flatMap { EngineWindowID.make($0.windowId) }
  }

  var focusedColumnIndex: Int? {
    focusedWindow.flatMap { tiledColumns.position(ofRawID: $0.windowId)?.column }
  }
}
