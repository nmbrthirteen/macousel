import Foundation
import StripCore
import WindowSystem
import os

nonisolated struct EngineSnapshot: Decodable, Equatable, Sendable {
  var version: Int
  var timestamp: Int?
  var active: EngineActive
  var virtualWorkspaces: [EngineWorkspace]
  var layout: EngineLayout?

  struct Bridged: Decodable {
    var state: EngineSnapshot
    var layout: EngineLayout?

    var snapshot: EngineSnapshot {
      var snapshot = state
      snapshot.layout = layout
      return snapshot
    }

    init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      state = try values.decode(EngineSnapshot.self, forKey: .state)
      // The layout only refines column grouping, so a snapshot without it still works.
      do {
        layout = try values.decodeIfPresent(EngineLayout.self, forKey: .layout)
      } catch {
        EngineSnapshot.logger.error("Could not read the engine layout: \(error, privacy: .public)")
        layout = nil
      }
    }

    private enum CodingKeys: String, CodingKey {
      case state, layout
    }
  }

  fileprivate static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  static func decode(_ text: String) -> EngineSnapshot? {
    do {
      return try decoder.decode(EngineSnapshot.self, from: Data(text.utf8))
    } catch {
      logger.error("Could not read the engine state: \(error, privacy: .public)")
      return nil
    }
  }

  static func decode(bridged text: String) -> EngineSnapshot? {
    do {
      return try decoder.decode(Bridged.self, from: Data(text.utf8)).snapshot
    } catch {
      logger.error("Could not read the bridged engine state: \(error, privacy: .public)")
      return nil
    }
  }

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()

  var visibleWindows: [EngineWindow] {
    let activeWorkspaces = virtualWorkspaces.filter(\.active)
    let windows = activeWorkspaces.flatMap(\.windows)
    guard let display = active.displayId else { return windows }
    return windows.filter { $0.displayId == nil || $0.displayId == display }
  }

  var tiledWindows: [EngineWindow] {
    visibleWindows.filter { !$0.floating }
  }

  var floatingWindows: [EngineWindow] {
    visibleWindows.filter { $0.floating && $0.visible }
  }

  // The engine reports a window pushed off screen as not visible and on no display.
  var activeFloatingWindows: [EngineWindow] {
    virtualWorkspaces.filter(\.active).flatMap(\.windows).filter(\.floating)
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
