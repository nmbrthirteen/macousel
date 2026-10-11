import Foundation

struct EnginePaths {
  let support: URL
  let logs: URL

  var config: URL { support.appendingPathComponent("paneru.toml") }
  var state: URL { support.appendingPathComponent("state", isDirectory: true) }
  var configHome: URL { support.appendingPathComponent("config", isDirectory: true) }
  var log: URL { logs.appendingPathComponent("engine.log") }

  static func system(fileManager: FileManager = .default) -> EnginePaths {
    let home = fileManager.homeDirectoryForCurrentUser
    return EnginePaths(
      support: home.appendingPathComponent("Library/Application Support/Macousel/engine", isDirectory: true),
      logs: home.appendingPathComponent("Library/Logs/Macousel", isDirectory: true))
  }
}
