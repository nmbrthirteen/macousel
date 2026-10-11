import Foundation

enum ArchiveUnpacker {
  static func unpack(_ archive: URL, into directory: URL) async throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let status: Int32
    do {
      status = try await ProcessRunner.run("/usr/bin/ditto", ["-x", "-k", archive.path, directory.path])
    } catch {
      throw UpdateInstallError.unpackFailed
    }
    guard status == 0 else { throw UpdateInstallError.unpackFailed }
  }
}
