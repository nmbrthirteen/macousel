import Foundation

enum SettingsFile {
  static let currentFormatVersion = 1
  static let defaultFileName = "macousel-settings.json"

  private struct Writing: Encodable {
    struct Shared: Encodable {
      let preferences: Preferences

      func encode(to encoder: Encoder) throws {
        try preferences.encode(to: encoder, includingOnboarding: false)
      }
    }

    let formatVersion: Int
    let preferences: Shared
  }

  private struct Reading: Decodable {
    let formatVersion: Int?
    let preferences: Preferences?
  }

  static func encode(_ preferences: Preferences) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(
      Writing(
        formatVersion: currentFormatVersion, preferences: .init(preferences: preferences)))
  }

  static func decode(_ data: Data, keepingOnboardingFrom current: Preferences) throws
    -> Preferences
  {
    let file: Reading
    do {
      file = try JSONDecoder().decode(Reading.self, from: data)
    } catch {
      throw SettingsFileError.notASettingsFile
    }
    let version = file.formatVersion ?? currentFormatVersion
    guard version <= currentFormatVersion else {
      throw SettingsFileError.unsupportedVersion(version)
    }
    guard var preferences = file.preferences else { throw SettingsFileError.missingPreferences }
    preferences.hasCompletedOnboarding = current.hasCompletedOnboarding
    return preferences
  }
}
