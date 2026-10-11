import AppKit

enum CommandLineClient {
  private static let listCommand = "list"
  private static let raycastCommand = "raycast-scripts"
  private static let usageExitCode: Int32 = 64
  private static let failureExitCode: Int32 = 1

  static func run(arguments: [String]) -> Int32? {
    if arguments.count == 2, arguments[0] == raycastCommand {
      return exportRaycastScripts(to: arguments[1])
    }
    guard arguments.count == 1, let command = arguments.first, !command.hasPrefix("-") else {
      return nil
    }
    if command == listCommand {
      write(Action.allCases.map(\.commandName).joined(separator: "\n") + "\n", to: .standardOutput)
      return 0
    }
    guard let action = Action(commandName: command) else {
      write(
        "Unknown command: \(command). Run 'Macousel list' to see the commands.\n",
        to: .standardError)
      return usageExitCode
    }
    guard let url = CommandURL.url(for: action), NSWorkspace.shared.open(url) else {
      write("Could not open \(command). Start Macousel once, then try again.\n", to: .standardError)
      return failureExitCode
    }
    return 0
  }

  private static func exportRaycastScripts(to path: String) -> Int32 {
    let directory = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    do {
      let count = try RaycastScriptExporter.export(to: directory)
      write("Wrote \(count) Raycast script commands to \(directory.path).\n", to: .standardOutput)
      return 0
    } catch {
      write(
        "Could not write to \(directory.path): \(error.localizedDescription)\n",
        to: .standardError)
      return failureExitCode
    }
  }

  private static func write(_ text: String, to handle: FileHandle) {
    handle.write(Data(text.utf8))
  }
}
