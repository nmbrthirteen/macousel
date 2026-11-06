import Testing

@testable import Macousel

@MainActor
struct ActionCommandTests {
  @Test(arguments: Action.allCases)
  func commandNameRoundTrips(action: Action) {
    #expect(Action(commandName: action.commandName) == action)
  }

  @Test(arguments: Action.allCases)
  func commandNameIsLowercaseKebabCase(action: Action) {
    #expect(action.commandName.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "-" })
  }

  @Test func commandNamesAreUnique() {
    #expect(Set(Action.allCases.map(\.commandName)).count == Action.allCases.count)
  }

  @Test func thereAreFiftyFourActions() {
    #expect(Action.allCases.count == 54)
  }

  @Test func floatingAndPreviousWindowCommandNames() {
    #expect(Action.switchToFloatingWindows.commandName == "switch-to-floating-windows")
    #expect(Action.bringBackFloatingWindows.commandName == "bring-back-floating-windows")
    #expect(Action.focusPrevious.commandName == "focus-previous")
  }

  @Test func floatingAndPreviousWindowTitles() {
    #expect(Action.switchToFloatingWindows.title == "Switch to floating windows")
    #expect(Action.bringBackFloatingWindows.title == "Bring back floating windows")
    #expect(Action.focusPrevious.title == "Focus previous window")
  }

  @Test func overviewAndScratchpadCommandNames() {
    #expect(Action.toggleOverview.commandName == "toggle-overview")
    #expect(Action.sendToScratchpad.commandName == "send-to-scratchpad")
    #expect(Action.toggleScratchpad.commandName == "toggle-scratchpad")
  }

  @Test func unknownCommandNameIsRejected() {
    #expect(Action(commandName: "fly-away") == nil)
  }

  @Test func everyActionButBringingBackFloatingWindowsHasADefaultShortcut() {
    for action in Action.allCases where action != .bringBackFloatingWindows {
      #expect(Action.defaultShortcuts[action]?.isEmpty == false)
    }
    #expect(Action.defaultShortcuts[.bringBackFloatingWindows] == nil)
  }

  @Test func defaultShortcutsNeverCollide() {
    let keys = Action.defaultShortcuts.values.flatMap { $0 }
    #expect(Set(keys).count == keys.count)
  }
}
