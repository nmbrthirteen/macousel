@testable import Macousel

@MainActor
final class FakeReleaseFeed: ReleaseFetching {
  var result: Result<Release, UpdateFeedError>
  private(set) var fetchCount = 0

  init(result: Result<Release, UpdateFeedError>) {
    self.result = result
  }

  func latestRelease() async throws -> Release {
    fetchCount += 1
    return try result.get()
  }
}
