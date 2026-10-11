import Foundation
import Testing

@testable import Macousel

@MainActor
struct DownloadPolicyTests {
  @Test(arguments: [
    "https://github.com/nmbrthirteen/macousel/releases/download/v0.2.0/Macousel.zip",
    "https://objects.githubusercontent.com/abc",
    "https://release-assets.githubusercontent.com/abc",
  ])
  func allowsHTTPSOnGitHubHosts(text: String) throws {
    let url = try #require(URL(string: text))

    #expect(DownloadPolicy.allows(url))
  }

  @Test(arguments: [
    "http://github.com/a/Macousel.zip",
    "https://evil.example/Macousel.zip",
    "https://github.com.evil.example/Macousel.zip",
    "https://notgithubusercontent.com/a",
    "https://githubusercontent.com/a",
    "file:///tmp/Macousel.zip",
  ])
  func rejectsOtherSchemesAndHosts(text: String) throws {
    let url = try #require(URL(string: text))

    #expect(!DownloadPolicy.allows(url))
  }

  @Test func refusesToDownloadFromAnUntrustedAssetURL() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let downloader = ArchiveDownloader(download: { _ in throw HTTPStatusError(code: 500) })
    let url = try #require(URL(string: "https://evil.example/Macousel.zip"))

    await #expect(throws: UpdateInstallError.untrustedDownload) {
      try await downloader.fetch(url, into: directory.url)
    }
  }

  @Test func refusesAFileWhoseRedirectLeftGitHub() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("tmp.download")
    try Data("zip".utf8).write(to: file)
    let evil = try #require(URL(string: "https://evil.example/Macousel.zip"))
    let downloader = ArchiveDownloader(download: { _ in (file, evil) })
    let url = try #require(URL(string: "https://github.com/a/Macousel.zip"))

    await #expect(throws: UpdateInstallError.untrustedDownload) {
      try await downloader.fetch(url, into: directory.url)
    }
    #expect(!FileManager.default.fileExists(atPath: file.path))
  }
}
