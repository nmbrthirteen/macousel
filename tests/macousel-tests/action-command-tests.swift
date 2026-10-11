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
    #expect(action.commandName.allSatisfy { $0.isLowercase || $0 == "-" })
  }

  @Test func commandNamesAreUnique() {
    #expect(Set(Action.allCases.map(\.commandName)).count == Action.allCases.count)
  }

  @Test func unknownCommandNameIsRejected() {
    #expect(Action(commandName: "fly-away") == nil)
  }

  @Test func everyActionHasADefaultShortcut() {
    for action in Action.allCases {
      #expect(Action.defaultShortcuts[action]?.isEmpty == false)
    }
  }

  @Test func defaultShortcutsNeverCollide() {
    let keys = Action.defaultShortcuts.values.flatMap { $0 }
    #expect(Set(keys).count == keys.count)
  }
}
