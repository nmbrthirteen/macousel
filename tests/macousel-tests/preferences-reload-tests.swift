import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct PreferencesReloadTests {
  @Test func reloadPicksUpPreferencesWrittenByAnotherStoreAndFiresTheCallback() throws {
    let suite = try IsolatedDefaults()
    let running = PreferencesStore(defaults: suite.defaults)
    var changes = 0
    running.onChange = { changes += 1 }
    let other = PreferencesStore(defaults: suite.defaults)
    other.preferences.showsMinimap = false
    other.preferences.swipeFingers = 3

    running.reload()

    #expect(running.preferences.showsMinimap == false)
    #expect(running.preferences.swipeFingers == 3)
    #expect(changes == 1)
  }

  @Test func anUnreadableStoredValueIsBackedUpBeforeDefaultsReplaceIt() throws {
    let suite = try IsolatedDefaults()
    let garbage = Data("not json".utf8)
    suite.defaults.set(garbage, forKey: "preferences")

    let store = PreferencesStore(defaults: suite.defaults)
    store.preferences.showsMinimap = false

    #expect(suite.defaults.data(forKey: PreferencesStore.backupKey) == garbage)
  }

  @Test func reloadWithNothingNewStaysQuiet() throws {
    let suite = try IsolatedDefaults()
    let running = PreferencesStore(defaults: suite.defaults)
    running.preferences.showsMinimap = false
    var changes = 0
    running.onChange = { changes += 1 }

    running.reload()

    #expect(running.preferences.showsMinimap == false)
    #expect(changes == 0)
  }

  @Test func reloadKeepsTheCurrentPreferencesWhenNothingIsStored() throws {
    let suite = try IsolatedDefaults()
    let running = PreferencesStore(defaults: suite.defaults)
    running.preferences.showsMinimap = false
    suite.defaults.removeObject(forKey: "preferences")

    running.reload()

    #expect(running.preferences.showsMinimap == false)
  }
}
