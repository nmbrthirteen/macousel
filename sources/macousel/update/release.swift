import Foundation

nonisolated struct Release: Equatable, Sendable, Decodable {
  static let archiveName = "Macousel.zip"

  let version: AppVersion
  let pageURL: URL
  let notes: String
  let archiveURL: URL

  private enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case pageURL = "html_url"
    case notes = "body"
    case assets
  }

  private nonisolated struct Asset: Decodable {
    let name: String
    let downloadURL: URL

    private enum CodingKeys: String, CodingKey {
      case name
      case downloadURL = "browser_download_url"
    }
  }

  init(version: AppVersion, pageURL: URL, notes: String, archiveURL: URL) {
    self.version = version
    self.pageURL = pageURL
    self.notes = notes
    self.archiveURL = archiveURL
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let tag = try values.decode(String.self, forKey: .tagName)
    guard let version = AppVersion(tag) else {
      throw DecodingError.dataCorruptedError(
        forKey: .tagName, in: values, debugDescription: "Tag is not a version")
    }
    let assets = try values.decode([Asset].self, forKey: .assets)
    guard let archive = assets.first(where: { $0.name == Self.archiveName }) else {
      throw DecodingError.dataCorruptedError(
        forKey: .assets, in: values, debugDescription: "No \(Self.archiveName) asset")
    }
    self.version = version
    pageURL = try values.decode(URL.self, forKey: .pageURL)
    notes = try values.decodeIfPresent(String.self, forKey: .notes) ?? ""
    archiveURL = archive.downloadURL
  }
}
