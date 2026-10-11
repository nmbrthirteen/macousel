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
