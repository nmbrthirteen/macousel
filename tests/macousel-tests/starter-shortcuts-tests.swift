import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct StarterShortcutsTests {
  @Test func columnJumpShowsTheLiveBindings() {
    #expect(StarterShortcutsStep.columnJumpKeys(in: Action.defaultShortcuts) == "⌥1 to ⌥9")
  }

  @Test func columnJumpFollowsACustomBinding() {
    var shortcuts = Action.defaultShortcuts
    shortcuts[.focusColumn(1)] = [Hotkey(keyCode: 18, modifiers: [.control, .command])]
    #expect(StarterShortcutsStep.columnJumpKeys(in: shortcuts) == "⌃⌘1 to ⌥9")
  }

  @Test func columnJumpReportsAMissingBinding() {
    var shortcuts = Action.defaultShortcuts
    shortcuts[.focusColumn(1)] = []
    #expect(StarterShortcutsStep.columnJumpKeys(in: shortcuts) == "Not set")
  }
}
