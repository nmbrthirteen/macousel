import Foundation

enum SettingsFileError: Error, Equatable, LocalizedError {
  case notASettingsFile
  case missingPreferences
  case unsupportedVersion(Int)

  var errorDescription: String? {
    switch self {
    case .notASettingsFile:
      "The file is not valid JSON. Choose a file that Macousel exported."
    case .missingPreferences:
      "The file has no \"preferences\" section. Choose a file that Macousel exported."
    case .unsupportedVersion(let version):
      "The file uses format version \(version), which this version of Macousel cannot read. Update Macousel and try again."
    }
  }
}
