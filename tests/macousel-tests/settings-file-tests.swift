import Carbon.HIToolbox
import Foundation
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct SettingsFileTests {
  private func customized() -> Preferences {
    var preferences = Preferences()
    preferences.layout.defaultWidth = 0.4
    preferences.shortcuts[.focusLeft] = [Hotkey(keyCode: UInt16(kVK_ANSI_Z), modifiers: [.command])]
    preferences.animationSpeed = .relaxed
    preferences.showsMinimap = false
    preferences.swipeFingers = 3
    preferences.focusFollowsMouse = true
    preferences.appRules = [AppRule(bundleIdentifier: "test.editor", behavior: .width(0.75))]
    preferences.appShortcuts = [
      AppShortcut(
        bundleIdentifier: "test.browser",
        hotkey: Hotkey(keyCode: UInt16(kVK_ANSI_B), modifiers: [.control, .option]))
    ]
    preferences.disabledDisplays = ["display-2"]
    preferences.checksForUpdates = false
    return preferences
  }

  private func decode(_ text: String, current: Preferences = Preferences()) throws -> Preferences {
    try SettingsFile.decode(Data(text.utf8), keepingOnboardingFrom: current)
  }

  @Test func aNonDefaultPreferencesValueSurvivesARoundTrip() throws {
    let original = customized()

    let data = try SettingsFile.encode(original)
    let loaded = try SettingsFile.decode(data, keepingOnboardingFrom: original)

    #expect(loaded == original)
  }

  @Test func fieldsLeftOutTakeTheirDefaults() throws {
    let loaded = try decode(#"{"formatVersion": 1, "preferences": {"showsMinimap": false}}"#)

    var expected = Preferences()
    expected.showsMinimap = false
    #expect(loaded == expected)
  }

  @Test func aMissingFormatVersionLoadsAsVersionOne() throws {
    let loaded = try decode(#"{"preferences": {"swipeFingers": 3}}"#)

    #expect(loaded.swipeFingers == 3)
  }

  @Test func aHigherFormatVersionIsRejectedWithAClearError() throws {
    let text = #"{"formatVersion": 2, "preferences": {}}"#

    #expect(throws: SettingsFileError.unsupportedVersion(2)) { try decode(text) }
    #expect(
      SettingsFileError.unsupportedVersion(2).localizedDescription
        == "The file uses format version 2, which this version of Macousel cannot read. Update Macousel and try again."
    )
  }

  @Test func invalidJSONIsRejected() {
    #expect(throws: SettingsFileError.notASettingsFile) { try decode("not json at all") }
  }

  @Test func aFileWithoutPreferencesIsRejected() {
    #expect(throws: SettingsFileError.missingPreferences) { try decode(#"{"formatVersion": 1}"#) }
  }

  @Test func theOnboardingFlagIsNeverWritten() throws {
    var preferences = customized()
    preferences.hasCompletedOnboarding = true

    let text = String(decoding: try SettingsFile.encode(preferences), as: UTF8.self)

    #expect(!text.contains("hasCompletedOnboarding"))
  }

  @Test func importKeepsTheCurrentOnboardingFlag() throws {
    var finished = Preferences()
    finished.hasCompletedOnboarding = true
    let fileSaysFinished = #"{"preferences": {"hasCompletedOnboarding": true}}"#
    let fileSaysNotFinished = #"{"preferences": {"hasCompletedOnboarding": false}}"#

    #expect(try decode(fileSaysFinished).hasCompletedOnboarding == false)
    #expect(try decode(fileSaysNotFinished, current: finished).hasCompletedOnboarding)
  }

  @Test func theEncodedFileHasSortedKeys() throws {
    let text = String(decoding: try SettingsFile.encode(customized()), as: UTF8.self)

    let topLevel = keys(in: text, indent: 2)
    let preferenceKeys = keys(in: text, indent: 4)
    #expect(topLevel == ["formatVersion", "preferences"])
    #expect(preferenceKeys.count > 10)
    #expect(preferenceKeys == preferenceKeys.sorted())
  }

  private func keys(in text: String, indent: Int) -> [String] {
    let prefix = String(repeating: " ", count: indent) + "\""
    return text.split(separator: "\n").compactMap { line in
      guard line.hasPrefix(prefix), line.contains("\" : ") else { return nil }
      return line.dropFirst(prefix.count).prefix { $0 != "\"" }.description
    }
  }
}
