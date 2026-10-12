import Foundation
import StripCore

nonisolated struct EngineSnapshot: Decodable, Equatable, Sendable {
  var version: Int
  var timestamp: Int?
  var active: EngineActive
  var virtualWorkspaces: [EngineWorkspace]
  var layout: EngineLayout?

  private struct Bridged: Decodable {
    var state: EngineSnapshot
    var layout: EngineLayout?

    init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      state = try values.decode(EngineSnapshot.self, forKey: .state)
      layout = try? values.decodeIfPresent(EngineLayout.self, forKey: .layout)
    }

    private enum CodingKeys: String, CodingKey {
      case state, layout
    }
  }

  static func decode(_ text: String) -> EngineSnapshot? {
    try? decoder.decode(EngineSnapshot.self, from: Data(text.utf8))
  }

  static func decode(bridged text: String) -> EngineSnapshot? {
    guard let bridged = try? decoder.decode(Bridged.self, from: Data(text.utf8)) else {
      return nil
    }
    var snapshot = bridged.state
    snapshot.layout = bridged.layout
    return snapshot
  }

  private static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
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
    EngineColumns(tiledWindows, grouping: layout?.columns(onDisplay: active.displayId))
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
