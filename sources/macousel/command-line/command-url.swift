import Foundation

enum CommandURL {
  static let scheme = "macousel"

  static func url(for action: Action) -> URL? {
    URL(string: "\(scheme)://\(action.commandName)")
  }

  static func action(from url: URL) -> Action? {
    guard url.scheme == scheme, let host = url.host else { return nil }
    return Action(commandName: host)
  }
}
