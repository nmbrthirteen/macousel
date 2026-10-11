import Foundation
import Testing

@testable import Macousel

@MainActor
struct DownloadPolicyTests {
  private static let releasePath = "/nmbrthirteen/macousel/releases/download/v0.2.0/Macousel.zip"

  @Test func allowsTheReleaseDownloadPathOnGitHub() throws {
    let url = try #require(URL(string: "https://github.com\(Self.releasePath)"))

    #expect(DownloadPolicy.allowsInitial(url))
  }

  @Test(arguments: [
    "http://github.com/nmbrthirteen/macousel/releases/download/v0.2.0/Macousel.zip",
    "https://github.com/someone-else/macousel/releases/download/v0.2.0/Macousel.zip",
    "https://github.com/nmbrthirteen/macousel/archive/main.zip",
    "https://github.com/nmbrthirteen/macousel/releases/downloads/v0.2.0/Macousel.zip",
    "https://objects.githubusercontent.com/nmbrthirteen/macousel/releases/download/v/Macousel.zip",
    "https://github.com.evil.example/nmbrthirteen/macousel/releases/download/v/Macousel.zip",
    "https://evil.example/nmbrthirteen/macousel/releases/download/v/Macousel.zip",
    "file:///tmp/Macousel.zip",
  ])
  func rejectsEveryOtherInitialURL(text: String) throws {
    let url = try #require(URL(string: text))

    #expect(!DownloadPolicy.allowsInitial(url))
  }

  @Test(arguments: [
    "https://objects.githubusercontent.com/abc",
    "https://release-assets.githubusercontent.com/abc",
  ])
  func allowsRedirectsToGitHubUserContentHosts(text: String) throws {
    let url = try #require(URL(string: text))

    #expect(DownloadPolicy.allowsRedirect(to: url))
  }

  @Test(arguments: [
    "http://objects.githubusercontent.com/abc",
    "https://github.com/nmbrthirteen/macousel/releases/download/v0.2.0/Macousel.zip",
    "https://evil.example/Macousel.zip",
    "https://notgithubusercontent.com/a",
    "https://githubusercontent.com/a",
    "https://objects.githubusercontent.com.evil.example/a",
    "file:///tmp/Macousel.zip",
  ])
  func rejectsRedirectsToAnyOtherHost(text: String) throws {
    let url = try #require(URL(string: text))

    #expect(!DownloadPolicy.allowsRedirect(to: url))
  }

  @Test(arguments: [
    ("https://github.com/nmbrthirteen/macousel/releases/tag/v0.2.0", true),
    ("http://github.com/nmbrthirteen/macousel/releases/tag/v0.2.0", false),
    ("https://evil.example/nmbrthirteen/macousel/releases/tag/v0.2.0", false),
    ("https://github.com.evil.example/releases", false),
    ("javascript:alert(1)", false),
  ])
  func showsTheReleasePageOnlyForHTTPSGitHubLinks(text: String, shown: Bool) throws {
    let url = try #require(URL(string: text))

    #expect(DownloadPolicy.isReleasePage(url) == shown)
  }

  @Test func theNotesLinkIsHiddenForAPageOutsideGitHub() throws {
    let release = try ReleaseJSON.release()
    let hostile = Release(
      version: release.version, pageURL: try #require(URL(string: "https://evil.example/notes")),
      notes: "", archiveURL: release.archiveURL, signatureURL: release.signatureURL)

    #expect(release.notesPageURL == release.pageURL)
    #expect(hostile.notesPageURL == nil)
  }

  @Test func refusesToDownloadFromAnUntrustedAssetURL() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let downloader = ArchiveDownloader(download: { _ in throw HTTPStatusError(code: 500) })
    let url = try #require(URL(string: "https://evil.example/Macousel.zip"))

    await #expect(throws: UpdateInstallError.untrustedDownload) {
      try await downloader.fetch(url, into: directory.url, named: Release.archiveName)
    }
  }

  @Test func refusesAGitHubURLOutsideTheReleaseDownloadPath() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let downloader = ArchiveDownloader(download: { _ in throw HTTPStatusError(code: 500) })
    let url = try #require(URL(string: "https://github.com/nmbrthirteen/macousel/archive/main.zip"))

    await #expect(throws: UpdateInstallError.untrustedDownload) {
      try await downloader.fetch(url, into: directory.url, named: Release.archiveName)
    }
  }

  @Test func refusesAFileWhoseRedirectLeftGitHubUserContent() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("tmp.download")
    try Data("zip".utf8).write(to: file)
    let evil = try #require(URL(string: "https://evil.example/Macousel.zip"))
    let downloader = ArchiveDownloader(download: { _ in (file, evil) })
    let url = try #require(URL(string: "https://github.com\(Self.releasePath)"))

    await #expect(throws: UpdateInstallError.untrustedDownload) {
      try await downloader.fetch(url, into: directory.url, named: Release.archiveName)
    }
    #expect(!FileManager.default.fileExists(atPath: file.path))
  }

  @Test func acceptsAFileServedAfterARedirectToGitHubUserContent() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("tmp.download")
    try Data("zip".utf8).write(to: file)
    let served = try #require(URL(string: "https://release-assets.githubusercontent.com/abc"))
    let downloader = ArchiveDownloader(download: { _ in (file, served) })
    let url = try #require(URL(string: "https://github.com\(Self.releasePath)"))

    let archive = try await downloader.fetch(url, into: directory.url, named: Release.archiveName)

    #expect(archive.lastPathComponent == Release.archiveName)
    #expect(FileManager.default.fileExists(atPath: archive.path))
  }
}
