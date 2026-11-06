import AppKit

enum CommandLineClient {
  private static let listCommand = "list"
  private static let raycastCommand = "raycast-scripts"
  private static let helpFlags: Set<String> = ["help", "-h", "--help"]
  private static let failureExitCode = CommandLineResult.failureStatus

  enum Invocation: Equatable {
    case output(CommandLineResult)
    case perform(Action)
  }

  static let usage = """
    Usage: Macousel <command>

    Commands:
      list                         Print every command name.
      <command>                    Run a command in the running Macousel.
      export-settings <path>       Write your settings to a file.
      import-settings <path>       Read your settings from a file.
      raycast-scripts <directory>  Write a Raycast script for each command.
      help                         Print this message.

    Run Macousel with no arguments to start the app.

    """

  static func run(arguments: [String]) -> Int32? {
    if arguments.count == 2, arguments[0] == raycastCommand {
      return exportRaycastScripts(to: arguments[1])
    }
    if let result = SettingsFileCommand.system.run(arguments: arguments) {
      write(result)
      return result.status
    }
    switch invocation(for: arguments) {
    case nil:
      return nil
    case .output(let result):
      write(result)
      return result.status
    case .perform(let action):
      guard let url = CommandURL.url(for: action), NSWorkspace.shared.open(url) else {
        write(
          "Could not open \(action.commandName). Start Macousel once, then try again.\n",
          to: .standardError)
        return failureExitCode
      }
      return 0
    }
  }

  static func invocation(for arguments: [String]) -> Invocation? {
    if let first = arguments.first, helpFlags.contains(first) {
      return .output(.success(usage))
    }
    guard arguments.count == 1, let command = arguments.first, !command.hasPrefix("-") else {
      return nil
    }
    if command == listCommand {
      let names = CommandURL.actions.map(\.commandName)
      return .output(.success(names.joined(separator: "\n") + "\n"))
    }
    guard let action = Action(commandName: command) else {
      return .output(
        .usage("Unknown command: \(command). Run 'Macousel list' to see the commands.\n"))
    }
    guard CommandURL.accepts(action) else {
      return .output(.usage("\(command) runs from its shortcut or the menu bar only.\n"))
    }
    return .perform(action)
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

  private static func write(_ result: CommandLineResult) {
    write(result.text, to: result.stream == .standardOutput ? .standardOutput : .standardError)
  }

  private static func write(_ text: String, to handle: FileHandle) {
    handle.write(Data(text.utf8))
  }
}
