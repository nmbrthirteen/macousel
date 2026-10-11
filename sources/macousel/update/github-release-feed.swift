import Foundation

struct GitHubReleaseFeed: ReleaseFetching {
  typealias Fetch = @Sendable (URLRequest) async throws -> Data

  nonisolated static let endpoint = URL(
    string: "https://api.github.com/repos/nmbrthirteen/macousel/releases/latest")!

  static let live: Fetch = { request in
    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
      throw HTTPStatusError(code: http.statusCode)
    }
    return data
  }

  let fetch: Fetch

  init(fetch: @escaping Fetch = GitHubReleaseFeed.live) {
    self.fetch = fetch
  }

  func latestRelease() async throws -> Release {
    var request = URLRequest(url: Self.endpoint)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("Macousel-Updater", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 20
    let data: Data
    do {
      data = try await fetch(request)
    } catch {
      throw UpdateFeedError(mapping: error)
    }
    do {
      return try JSONDecoder().decode(Release.self, from: data)
    } catch {
      throw UpdateFeedError.unexpectedResponse
    }
  }
}
