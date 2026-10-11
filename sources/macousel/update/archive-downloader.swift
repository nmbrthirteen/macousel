import Foundation

struct ArchiveDownloader {
  typealias Download = @Sendable (URL) async throws -> (file: URL, finalURL: URL)

  static let live: Download = { url in
    let (file, response) = try await URLSession.shared.download(from: url)
    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
      throw HTTPStatusError(code: http.statusCode)
    }
    return (file, response.url ?? url)
  }

  let download: Download

  init(download: @escaping Download = ArchiveDownloader.live) {
    self.download = download
  }

  func fetch(_ url: URL, into directory: URL) async throws -> URL {
    guard DownloadPolicy.allows(url) else { throw UpdateInstallError.untrustedDownload }
    let result: (file: URL, finalURL: URL)
    do {
      result = try await download(url)
    } catch {
      throw UpdateInstallError.downloadFailed
    }
    guard DownloadPolicy.allows(result.finalURL) else {
      try? FileManager.default.removeItem(at: result.file)
      throw UpdateInstallError.untrustedDownload
    }
    let destination = directory.appendingPathComponent(Release.archiveName)
    try FileManager.default.moveItem(at: result.file, to: destination)
    return destination
  }
}
