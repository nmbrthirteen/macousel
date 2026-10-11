import Foundation
import Testing

@testable import Macousel

@MainActor
struct GitHubReleaseFeedTests {
  private func feed(failingWith error: Error) -> GitHubReleaseFeed {
    GitHubReleaseFeed(fetch: { _ in throw error })
  }

  @Test func returnsTheLatestReleaseAndSendsTheGitHubHeaders() async throws {
    let feed = GitHubReleaseFeed(fetch: { request in
      guard request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json",
        request.value(forHTTPHeaderField: "User-Agent") != nil,
        request.url == GitHubReleaseFeed.endpoint
      else { throw HTTPStatusError(code: 400) }
      return ReleaseJSON.data()
    })

    let release = try await feed.latestRelease()

    #expect(release.version == AppVersion("0.2.0"))
  }

  @Test(arguments: [
    URLError.Code.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
  ])
  func mapsConnectionFailuresToNoConnection(code: URLError.Code) async {
    let feed = feed(failingWith: URLError(code))

    await #expect(throws: UpdateFeedError.noConnection) { try await feed.latestRelease() }
  }

  @Test(arguments: [403, 429])
  func mapsRateLimitStatusesToRateLimited(status: Int) async {
    let feed = feed(failingWith: HTTPStatusError(code: status))

    await #expect(throws: UpdateFeedError.rateLimited) { try await feed.latestRelease() }
  }

  @Test func mapsOtherStatusesToUnexpectedResponse() async {
    let feed = feed(failingWith: HTTPStatusError(code: 500))

    await #expect(throws: UpdateFeedError.unexpectedResponse) { try await feed.latestRelease() }
  }

  @Test func mapsUnreadableJSONToUnexpectedResponse() async {
    let feed = GitHubReleaseFeed(fetch: { _ in Data("<html></html>".utf8) })

    await #expect(throws: UpdateFeedError.unexpectedResponse) { try await feed.latestRelease() }
  }

  @Test func mapsAReleaseWithoutTheZipToUnexpectedResponse() async {
    let feed = GitHubReleaseFeed(fetch: { _ in ReleaseJSON.data(assets: ["Macousel.dmg"]) })

    await #expect(throws: UpdateFeedError.unexpectedResponse) { try await feed.latestRelease() }
  }

  @Test func everyErrorSaysWhatToDoNext() {
    let errors: [UpdateFeedError] = [.noConnection, .rateLimited, .unexpectedResponse]

    #expect(errors.allSatisfy { !$0.message.isEmpty })
    #expect(Set(errors.map(\.message)).count == errors.count)
  }
}
