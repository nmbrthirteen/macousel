import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct CommandLineClientTests {
  @Test(arguments: ["help", "-h", "--help"])
  func helpPrintsTheUsageAndSucceeds(flag: String) {
    let invocation = CommandLineClient.invocation(for: [flag])

    #expect(invocation == .output(.success(CommandLineClient.usage)))
  }

  @Test func theUsageNamesEveryNonActionCommand() {
    for name in ["list", "export-settings", "import-settings", "raycast-scripts", "help"] {
      #expect(CommandLineClient.usage.contains(name))
    }
  }

  @Test func listPrintsOneCommandNamePerLine() throws {
    let invocation = try #require(CommandLineClient.invocation(for: ["list"]))

    guard case .output(let result) = invocation else {
      Issue.record("Expected output")
      return
    }
    #expect(result.status == 0)
    #expect(result.text.split(separator: "\n").count == CommandURL.actions.count)
  }

  @Test func anUnknownCommandIsAUsageError() {
    let invocation = CommandLineClient.invocation(for: ["no-such-command"])

    #expect(
      invocation
        == .output(
          .usage("Unknown command: no-such-command. Run 'Macousel list' to see the commands.\n")))
  }

  @Test func aKnownCommandIsPerformed() throws {
    let action = try #require(CommandURL.actions.first)

    #expect(CommandLineClient.invocation(for: [action.commandName]) == .perform(action))
  }

  @Test(arguments: [["-psn_0_12345"], ["-NSDocumentRevisionsDebugMode"], []])
  func dashArgumentsAndNoArgumentsLaunchTheApp(arguments: [String]) {
    #expect(CommandLineClient.invocation(for: arguments) == nil)
  }
}
