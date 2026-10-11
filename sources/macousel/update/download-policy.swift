import Foundation

nonisolated enum DownloadPolicy {
  static let releaseDownloadPathPrefix = "/nmbrthirteen/macousel/releases/download/"
  static let redirectHostSuffix = ".githubusercontent.com"

  static func allowsInitial(_ url: URL) -> Bool {
    isHTTPS(url) && url.host?.lowercased() == "github.com"
      && url.path.hasPrefix(releaseDownloadPathPrefix)
  }

  static func allowsRedirect(to url: URL) -> Bool {
    guard isHTTPS(url), let host = url.host?.lowercased() else { return false }
    return host.hasSuffix(redirectHostSuffix)
  }

  static func allowsDestination(_ destination: URL, requested: URL) -> Bool {
    destination == requested || allowsRedirect(to: destination)
  }

  static func isReleasePage(_ url: URL) -> Bool {
    isHTTPS(url) && url.host?.lowercased() == "github.com"
  }

  private static func isHTTPS(_ url: URL) -> Bool {
    url.scheme?.lowercased() == "https"
  }
}
