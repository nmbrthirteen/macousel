import Foundation
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ShortcutBaseTests {
  @Test(arguments: ShortcutBase.allCases)
  func everyBaseKeepsHotkeysUnique(base: ShortcutBase) {
    let hotkeys = Action.defaultShortcuts(base: base).values.flatMap { $0 }
    #expect(Set(hotkeys).count == hotkeys.count)
  }

  @Test func controlOptionMatchesTheStaticDefaults() {
    #expect(Action.defaultShortcuts(base: .controlOption) == Action.defaultShortcuts)
  }

  @Test func optionDropsControl() {
    let hotkeys = Action.defaultShortcuts(base: .option).values.flatMap { $0 }
    #expect(
      hotkeys.allSatisfy { !$0.modifiers.contains(.control) && $0.modifiers.contains(.option) })
    #expect(Action.defaultShortcuts(base: .option)[.focusLeft]?.first?.modifiers == [.option])
  }

  @Test func commandOptionSwapsControlAndCommand() {
    let shortcuts = Action.defaultShortcuts(base: .commandOption)
    #expect(shortcuts[.focusLeft]?.first?.modifiers == [.command, .option])
    #expect(shortcuts[.focusFirst]?.first?.modifiers == [.control, .option, .command])
    #expect(shortcuts[.moveToFirst]?.first?.modifiers == [.control, .option, .command, .shift])
  }

  @Test func switchingBaseKeepsACustomizedAction() throws {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    let custom = [Hotkey(keyCode: 18, modifiers: [.control, .shift])]
    store.preferences.shortcuts[.center] = custom

    store.setShortcutBase(.option)

    #expect(store.preferences.shortcutBase == .option)
    #expect(store.preferences.shortcuts[.center] == custom)
    #expect(
      store.preferences.shortcuts[.focusLeft] == Action.defaultShortcuts(base: .option)[.focusLeft])
  }

  @Test func switchingBackRestoresTheOriginalDefaults() throws {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)

    store.setShortcutBase(.commandOption)
    store.setShortcutBase(.controlOption)

    #expect(store.preferences.shortcuts == Action.defaultShortcuts)
  }

  @Test func switchingBaseSavesOnce() throws {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    var changes = 0
    store.onChange = { changes += 1 }

    store.setShortcutBase(.option)

    #expect(changes == 1)
  }

  @Test func oldPreferencesWithoutTheKeyUseControlOption() throws {
    let preferences = try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8))
    #expect(preferences.shortcutBase == .controlOption)
    #expect(preferences.shortcuts == Action.defaultShortcuts)
  }

  @Test func decodingMergesDefaultsForTheSavedBase() throws {
    let preferences = try JSONDecoder().decode(
      Preferences.self, from: Data(#"{"shortcutBase":"option"}"#.utf8))
    #expect(preferences.shortcuts == Action.defaultShortcuts(base: .option))
  }

  @Test func resetUsesTheCurrentBase() throws {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    store.setShortcutBase(.commandOption)
    store.preferences.shortcuts[.center] = []

    store.resetShortcuts()

    #expect(store.preferences.shortcuts == Action.defaultShortcuts(base: .commandOption))
  }
}
