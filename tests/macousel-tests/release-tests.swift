import Foundation
import Testing

@testable import Macousel

@MainActor
struct ReleaseTests {
  @Test func decodesAGitHubReleaseResponse() throws {
    let release = try JSONDecoder().decode(Release.self, from: ReleaseJSON.data(tag: "v0.2.0"))

    #expect(release.version == AppVersion("0.2.0"))
    #expect(release.notes == "Fixes focus after wake.")
    #expect(
      release.pageURL.absoluteString
        == "https://github.com/nmbrthirteen/macousel/releases/tag/v0.2.0")
    #expect(
      release.archiveURL.absoluteString
        == "https://github.com/nmbrthirteen/macousel/releases/download/v0.2.0/Macousel.zip")
    #expect(
      release.signatureURL.absoluteString
        == "https://github.com/nmbrthirteen/macousel/releases/download/v0.2.0/Macousel.zip.sig")
  }

  @Test func rejectsAReleaseWithoutTheSignatureAsset() {
    let data = ReleaseJSON.data(assets: ["Macousel.dmg", "Macousel.zip", "install.sh"])

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Release.self, from: data)
    }
  }

  @Test func rejectsAReleaseWithoutTheZipAsset() {
    let data = ReleaseJSON.data(assets: ["Macousel.dmg", "install.sh"])

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Release.self, from: data)
    }
  }

  @Test func rejectsAReleaseWithAnUnparseableTag() {
    let data = ReleaseJSON.data(tag: "nightly")

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Release.self, from: data)
    }
  }
}
