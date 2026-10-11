import Foundation

enum DownloadPolicy {
  static func allows(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
    return host == "github.com" || host.hasSuffix(".githubusercontent.com")
  }
}
