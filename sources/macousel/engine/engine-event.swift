import Foundation

nonisolated enum EngineEvent: Decodable, Equatable, Sendable {
  case virtualWorkspaceChanged(EngineActive)
  case windowsChanged(workspace: Int?, active: EngineActive)
  case windowFocused(windowId: Int32?, bundleId: String?, title: String?, workspace: Int?)
  case onScreenChanged(windows: [EngineWindow], active: EngineActive)
  case windowTitleChanged(windowId: Int32, title: String)
  case displayChanged(displayId: UInt32?)
  case unrecognized(String)

  private enum CodingKeys: String, CodingKey {
    case event, active, windowId, bundleId, title, virtualWorkspaceNumber, windows, displayId
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let name = try values.decode(String.self, forKey: .event)
    let active = try values.decodeIfPresent(EngineActive.self, forKey: .active) ?? EngineActive()
    let workspace = try values.decodeIfPresent(Int.self, forKey: .virtualWorkspaceNumber)
    switch name {
    case "virtual_workspace_changed":
      self = .virtualWorkspaceChanged(active)
    case "windows_changed":
      self = .windowsChanged(workspace: workspace, active: active)
    case "window_focused":
      self = .windowFocused(
        windowId: try values.decodeIfPresent(Int32.self, forKey: .windowId),
        bundleId: try values.decodeIfPresent(String.self, forKey: .bundleId),
        title: try values.decodeIfPresent(String.self, forKey: .title), workspace: workspace)
    case "on_screen_changed":
      self = .onScreenChanged(
        windows: try values.decodeIfPresent([EngineWindow].self, forKey: .windows) ?? [],
        active: active)
    case "window_title_changed":
      self = .windowTitleChanged(
        windowId: try values.decode(Int32.self, forKey: .windowId),
        title: try values.decode(String.self, forKey: .title))
    case "display_changed":
      self = .displayChanged(displayId: try values.decodeIfPresent(UInt32.self, forKey: .displayId))
    default:
      self = .unrecognized(name)
    }
  }

  static func decode(line: String) -> EngineEvent? {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try? decoder.decode(EngineEvent.self, from: Data(line.utf8))
  }
}
