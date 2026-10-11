import Foundation

nonisolated final class RedirectGuard: NSObject, URLSessionTaskDelegate {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest
  ) async -> URLRequest? {
    guard let target = request.url, DownloadPolicy.allowsRedirect(to: target) else { return nil }
    return request
  }
}
