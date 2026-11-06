import Foundation
import Testing

@testable import Macousel

@MainActor
struct ShowInDockTests {
  @Test func theDockIconIsHiddenByDefault() {
    #expect(!Preferences().showsInDock)
  }

  @Test func missingSettingDecodesAsHidden() throws {
    let decoded = try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8))
    #expect(!decoded.showsInDock)
  }

  @Test func theSettingSurvivesAnExportAndImport() throws {
    var preferences = Preferences()
    preferences.showsInDock = true

    let data = try SettingsFile.encode(preferences)
    let loaded = try SettingsFile.decode(data, keepingOnboardingFrom: Preferences())

    #expect(loaded.showsInDock)
  }

  @Test func aValueOfTheWrongTypeIsRejectedOnImport() {
    let text = Data(#"{"preferences": {"showsInDock": "yes"}}"#.utf8)

    #expect(throws: SettingsFileError.invalidValue("showsInDock")) {
      try SettingsFile.decode(text, keepingOnboardingFrom: Preferences())
    }
  }
}
