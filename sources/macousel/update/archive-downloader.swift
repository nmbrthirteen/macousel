import Foundation

struct ArchiveDownloader {
  typealias Download = @Sendable (URL) async throws -> (file: URL, finalURL: URL)

  static let live: Download = { url in
    let (file, response) = try await URLSession.shared.download(
      from: url, delegate: RedirectGuard())
    if let http = response as? HTTPURLResponse {
      if (300..<400).contains(http.statusCode) { throw UpdateInstallError.untrustedDownload }
      if !(200..<300).contains(http.statusCode) { throw HTTPStatusError(code: http.statusCode) }
    }
    return (file, response.url ?? url)
  }

  let download: Download

  init(download: @escaping Download = ArchiveDownloader.live) {
    self.download = download
  }

  func fetch(_ url: URL, into directory: URL, named name: String) async throws -> URL {
    guard DownloadPolicy.allowsInitial(url) else { throw UpdateInstallError.untrustedDownload }
    let result: (file: URL, finalURL: URL)
    do {
      result = try await download(url)
    } catch let error as UpdateInstallError {
      throw error
    } catch {
      throw UpdateInstallError.downloadFailed
    }
    guard DownloadPolicy.allowsDestination(result.finalURL, requested: url) else {
      try? FileManager.default.removeItem(at: result.file)
      throw UpdateInstallError.untrustedDownload
    }
    let destination = directory.appendingPathComponent(name)
    try FileManager.default.moveItem(at: result.file, to: destination)
    return destination
  }
}
