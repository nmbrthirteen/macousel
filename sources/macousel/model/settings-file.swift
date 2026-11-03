import Foundation

enum SettingsFile {
  static let currentFormatVersion = 1
  static let defaultFileName = "macousel-settings.json"

  private struct Writing: Encodable {
    struct Shared: Encodable {
      let preferences: Preferences

      func encode(to encoder: Encoder) throws {
        try preferences.encode(
          to: encoder, includingOnboarding: false, sortingUnorderedValues: true)
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
    guard (try? JSONSerialization.jsonObject(with: data)) is [String: Any] else {
      throw SettingsFileError.notASettingsFile
    }
    let decoder = JSONDecoder()
    decoder.userInfo[Preferences.strictDecoding] = true
    let file: Reading
    do {
      file = try decoder.decode(Reading.self, from: data)
    } catch let error as DecodingError {
      throw SettingsFileError.invalidValue(error.fieldPath)
    }
    let version = file.formatVersion ?? currentFormatVersion
    guard version <= currentFormatVersion else {
      throw SettingsFileError.unsupportedVersion(version)
    }
    guard var preferences = file.preferences else { throw SettingsFileError.missingPreferences }
    if let field = preferences.outOfRangeValue { throw SettingsFileError.invalidValue(field) }
    preferences.hasCompletedOnboarding = current.hasCompletedOnboarding
    return preferences
  }
}

extension DecodingError {
  fileprivate var fieldPath: String {
    let path: [any CodingKey]
    switch self {
    case .typeMismatch(_, let context), .valueNotFound(_, let context),
      .dataCorrupted(let context):
      path = context.codingPath
    case .keyNotFound(let key, let context):
      path = context.codingPath + [key]
    @unknown default:
      path = []
    }
    let names = path.map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }
      .filter { $0 != "preferences" }
    return names.isEmpty ? "preferences" : names.joined(separator: ".")
  }
}
