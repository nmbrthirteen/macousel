import Foundation

enum CommandURL {
  static let scheme = "macousel"
  private static let reloadSettingsHost = "reload-settings"

  static var reloadSettings: URL? {
    URL(string: "\(scheme)://\(reloadSettingsHost)")
  }

  static func isReloadSettings(_ url: URL) -> Bool {
    url.scheme == scheme && url.host == reloadSettingsHost
  }

  static func url(for action: Action) -> URL? {
    URL(string: "\(scheme)://\(action.commandName)")
  }

  static func action(from url: URL) -> Action? {
    guard url.scheme == scheme, let host = url.host else { return nil }
    return Action(commandName: host)
  }
}
