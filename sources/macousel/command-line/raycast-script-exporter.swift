import Foundation

enum RaycastScriptExporter {
  private static let executablePermissions = 0o755

  static func fileName(for action: Action) -> String {
    "macousel-\(action.commandName).sh"
  }

  static func script(for action: Action) -> String {
    """
    #!/bin/bash
    # @raycast.schemaVersion 1
    # @raycast.title \(action.title)
    # @raycast.mode silent
    # @raycast.packageName Macousel
    open -g "\(CommandURL.scheme)://\(action.commandName)"

    """
  }

  static func export(to directory: URL) throws -> Int {
    let files = FileManager.default
    try files.createDirectory(at: directory, withIntermediateDirectories: true)
    for action in Action.allCases {
      let file = directory.appendingPathComponent(fileName(for: action))
      try Data(script(for: action).utf8).write(to: file)
      try files.setAttributes([.posixPermissions: executablePermissions], ofItemAtPath: file.path)
    }
    return Action.allCases.count
  }
}
