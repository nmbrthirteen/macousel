import AppKit
import Foundation

struct UpdateInstaller: ReleaseInstalling {
  let runningBundleURL: URL
  let downloader: ArchiveDownloader
  let validator: BundleValidator
  var verifier = UpdateSignatureVerifier()
  var workRoot = FileManager.default.temporaryDirectory

  static func running(bundle: Bundle = .main) -> UpdateInstaller {
    let info = BundleInfo(bundle: bundle)
    return UpdateInstaller(
      runningBundleURL: bundle.bundleURL,
      downloader: ArchiveDownloader(),
      validator: BundleValidator(
        runningIdentifier: info.identifier ?? "", runningVersion: info.version ?? .zero))
  }

  func prepare(_ release: Release) async throws -> PreparedUpdate {
    let files = FileManager.default
    let work = workRoot.appendingPathComponent("macousel-update-\(UUID().uuidString)", isDirectory: true)
    try files.createDirectory(at: work, withIntermediateDirectories: true)
    do {
      let archive = try await downloader.fetch(
        release.archiveURL, into: work, named: Release.archiveName)
      let signature = try await downloader.fetch(
        release.signatureURL, into: work, named: Release.signatureName)
      guard verifier.isValid(signatureFile: signature, archiveFile: archive) else {
        throw UpdateInstallError.unverifiedUpdate
      }
      let unpacked = work.appendingPathComponent("unpacked", isDirectory: true)
      try await ArchiveUnpacker.unpack(archive, into: unpacked)
      let bundle = try await validator.validate(unpackedIn: unpacked)
      return PreparedUpdate(bundleURL: bundle, workDirectory: work)
    } catch {
      try? files.removeItem(at: work)
      throw error
    }
  }

  func apply(_ update: PreparedUpdate) throws {
    do {
      try BundleSwapper().swap(installed: runningBundleURL, with: update.bundleURL)
    } catch {
      try? FileManager.default.removeItem(at: update.workDirectory)
      throw error
    }
    try? FileManager.default.removeItem(at: update.workDirectory)
    try AppRelauncher().start(opening: runningBundleURL)
    NSApp.terminate(nil)
  }
}
