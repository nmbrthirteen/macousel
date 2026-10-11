import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DefaultRuleTests {
  private func roundTripped(_ preferences: Preferences) throws -> Preferences {
    try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(preferences))
  }

  @Test func freshPreferencesFloatSystemSettingsAndCalculator() {
    let preferences = Preferences()

    #expect(preferences.rule(for: "com.apple.systempreferences") == .float)
    #expect(preferences.rule(for: "com.apple.calculator") == .float)
    #expect(preferences.appRules == AppRule.defaults)
    #expect(Set(AppRule.defaults.map(\.bundleIdentifier)).count == 8)
  }

  @Test func savedPreferencesWithAnEmptyRuleListStayEmpty() throws {
    var preferences = Preferences()
    preferences.appRules = []

    let decoded = try roundTripped(preferences)

    #expect(decoded.appRules.isEmpty)
  }

  @Test func savedPreferencesKeepTheirOwnRuleList() throws {
    var preferences = Preferences()
    preferences.appRules = [AppRule(bundleIdentifier: "test.editor", behavior: .width(0.4))]

    let decoded = try roundTripped(preferences)

    #expect(decoded.appRules == preferences.appRules)
  }

  @Test func preferencesWithoutARuleListFallToTheDefaults() throws {
    let decoded = try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8))

    #expect(decoded.appRules == AppRule.defaults)
  }

  @Test func savedShortcutsWithoutTheColumnActionsGainTheirDefaults() throws {
    var preferences = Preferences()
    preferences.shortcuts[.focusColumn3] = nil
    preferences.shortcuts[.focusLeft] = []

    let decoded = try roundTripped(preferences)

    #expect(decoded.shortcuts[.focusColumn3] == Action.defaultShortcuts[.focusColumn3])
    #expect(decoded.shortcuts[.focusLeft] == [])
  }

  @Test func newPreferencesShowTheFocusBorderAndFollowThePointerAcrossDisplays() {
    let preferences = Preferences()

    #expect(preferences.showsFocusBorder)
    #expect(preferences.displayFollowsPointer)
    #expect(!preferences.focusFollowsMouse)
  }

  @Test func aWindowFromADefaultFloatedAppIsNotTiled() throws {
    let fixture = try ControllerFixture()
    let calculator = FakeApp(pid: 400, bundleIdentifier: "com.apple.calculator", name: "Calculator")
    let editor = fixture.open(1, atX: 100, activating: true)
    let floating = fixture.open(2, app: calculator, atX: 300)
    let floatingFrame = floating.frame

    fixture.launch()

    #expect(floating.framesSet.isEmpty)
    #expect(floating.frame == floatingFrame)
    #expect(editor.framesSet.count == 1)
  }
}
