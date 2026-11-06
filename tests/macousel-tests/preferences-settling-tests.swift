import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct PreferencesSettlingTests {
  private let settle = Duration.milliseconds(150)

  private func launched(settleDelay: Duration) throws -> ControllerFixture {
    let fixture = try ControllerFixture(settleDelay: settleDelay)
    fixture.launch()
    return fixture
  }

  @Test func rapidChangesApplyOnceAfterThePause() throws {
    let fixture = try launched(settleDelay: settle)
    let applied = fixture.shortcuts.setBindingsCount

    fixture.store.preferences.swipeFingers = 3
    fixture.clock.advance(by: .milliseconds(100))
    fixture.store.preferences.swipeFingers = 4
    fixture.clock.advance(by: .milliseconds(100))
    fixture.store.preferences.swipeFingers = 3
    #expect(fixture.shortcuts.setBindingsCount == applied)

    fixture.clock.advance(by: settle)

    #expect(fixture.shortcuts.setBindingsCount == applied + 1)
    #expect(fixture.gestures.swipeFingerCount == 3)
  }

  @Test func theValueIsSavedBeforeItIsApplied() throws {
    let fixture = try launched(settleDelay: settle)

    fixture.store.preferences.swipeFingers = 3

    let stored = PreferencesStore(defaults: fixture.suite.defaults)
    #expect(stored.preferences.swipeFingers == 3)
  }

  @Test func recordingAShortcutAppliesAtOnce() throws {
    let fixture = try launched(settleDelay: settle)
    let browser = fixture.store.preferences.shortcuts.values.flatMap { $0 }.first
    let key = try #require(browser)
    #expect(fixture.shortcuts.boundHotkeys.contains(key))

    fixture.store.isRecordingShortcut = true
    #expect(fixture.shortcuts.boundHotkeys.isEmpty)

    fixture.store.isRecordingShortcut = false
    #expect(fixture.shortcuts.boundHotkeys.contains(key))
  }

  @Test func quittingDropsAPendingApply() throws {
    let fixture = try launched(settleDelay: settle)
    fixture.store.preferences.swipeFingers = 3
    fixture.quit()
    let applied = fixture.shortcuts.setBindingsCount

    fixture.clock.advance(by: settle)

    #expect(fixture.shortcuts.setBindingsCount == applied)
  }

  @Test func changesTheInputsDoNotReadLeaveTheRegisteredInputAlone() throws {
    let fixture = try launched(settleDelay: .zero)
    let applied = fixture.shortcuts.setBindingsCount

    fixture.store.preferences.showsMinimap.toggle()
    fixture.store.preferences.layout.defaultWidth = 0.4

    #expect(fixture.shortcuts.setBindingsCount == applied)
  }

  @Test func changesTheInputsReadRegisterThemAgain() throws {
    let fixture = try launched(settleDelay: .zero)
    let applied = fixture.shortcuts.setBindingsCount

    fixture.store.preferences.swipeFingers = 3

    #expect(fixture.shortcuts.setBindingsCount == applied + 1)
  }
}
