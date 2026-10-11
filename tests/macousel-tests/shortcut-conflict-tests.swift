import Carbon.HIToolbox
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ShortcutConflictTests {
  private let free = Hotkey(keyCode: UInt16(kVK_ANSI_B), modifiers: [.control, .option])
  private let editor = FakeApp.editor.bundleIdentifier
  private let browser = FakeApp.browser.bundleIdentifier

  private func store() throws -> PreferencesStore {
    PreferencesStore(defaults: try IsolatedDefaults().defaults)
  }

  @Test func anAppCannotTakeACombinationAnActionUses() throws {
    let store = try store()
    let taken = try #require(Action.defaultShortcuts[.focusLeft]?.first)
    let recording = ShortcutRecording(target: .app(editor), store: store)

    recording.record(taken)

    #expect(recording.message?.contains("Focus left") == true)
    #expect(store.preferences.appShortcuts.isEmpty)
  }

  @Test func anActionCannotTakeACombinationAnAppUses() throws {
    let store = try store()
    store.preferences.appShortcuts = [AppShortcut(bundleIdentifier: browser, hotkey: free)]
    let recording = ShortcutRecording(target: .action(.focusLeft), store: store)

    recording.record(free)

    #expect(recording.message?.contains(browser) == true)
    #expect(store.preferences.shortcuts[.focusLeft]?.contains(free) == false)
  }

  @Test func twoAppsCannotShareACombination() throws {
    let store = try store()
    store.preferences.appShortcuts = [AppShortcut(bundleIdentifier: browser, hotkey: free)]
    let recording = ShortcutRecording(target: .app(editor), store: store)

    recording.record(free)

    #expect(recording.message?.contains(browser) == true)
    #expect(store.preferences.appShortcuts.map(\.bundleIdentifier) == [browser])
  }

  @Test func aFreeCombinationIsAssignedToANewApp() throws {
    let store = try store()
    let recording = ShortcutRecording(target: .app(editor), store: store)

    recording.record(free)

    #expect(recording.message == nil)
    #expect(store.preferences.appShortcuts == [AppShortcut(bundleIdentifier: editor, hotkey: free)])
  }

  @Test func recordingAgainReplacesTheAppsCombination() throws {
    let store = try store()
    let replacement = Hotkey(keyCode: UInt16(kVK_ANSI_M), modifiers: [.control, .option])
    store.preferences.appShortcuts = [AppShortcut(bundleIdentifier: editor, hotkey: free)]
    let recording = ShortcutRecording(target: .app(editor), store: store)

    recording.record(replacement)

    let expected = AppShortcut(bundleIdentifier: editor, hotkey: replacement)
    #expect(store.preferences.appShortcuts == [expected])
  }
}
