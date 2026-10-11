import Foundation
import Testing

@testable import Macousel

enum ReleaseJSON {
  static func make(tag: String = "v0.2.0", assets: [String] = ["Macousel.dmg", "Macousel.zip", "Macousel.zip.sig", "install.sh"]) -> String {
    let entries = assets.map { name in
      """
      {"name": "\(name)", "size": 1024, "state": "uploaded", \
      "browser_download_url": "https://github.com/nmbrthirteen/macousel/releases/download/\(tag)/\(name)"}
      """
    }.joined(separator: ",")
    return """
      {"url": "https://api.github.com/repos/nmbrthirteen/macousel/releases/1",
       "html_url": "https://github.com/nmbrthirteen/macousel/releases/tag/\(tag)",
       "tag_name": "\(tag)", "name": "\(tag)", "draft": false, "prerelease": false,
       "body": "Fixes focus after wake.", "assets": [\(entries)]}
      """
  }

  static func data(tag: String = "v0.2.0", assets: [String] = ["Macousel.dmg", "Macousel.zip", "Macousel.zip.sig", "install.sh"]) -> Data {
    Data(make(tag: tag, assets: assets).utf8)
  }

  static func release(version: String = "0.2.0") throws -> Release {
    let base = "https://github.com/nmbrthirteen/macousel/releases"
    return Release(
      version: try #require(AppVersion(version)),
      pageURL: try #require(URL(string: "\(base)/tag/v\(version)")),
      notes: "Notes",
      archiveURL: try #require(URL(string: "\(base)/download/v\(version)/Macousel.zip")),
      signatureURL: try #require(URL(string: "\(base)/download/v\(version)/Macousel.zip.sig")))
  }
}
