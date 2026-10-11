import Foundation
import os

struct BundleSwapper {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "updates")

  func swap(installed: URL, with replacement: URL) throws {
    let files = FileManager.default
    let parent = installed.deletingLastPathComponent()
    try requireReplaceable(installed: installed, parent: parent)

    let backup = parent.appendingPathComponent(".\(installed.lastPathComponent).previous")
    try? files.removeItem(at: backup)
    do {
      try files.moveItem(at: installed, to: backup)
    } catch {
      throw UpdateInstallError.swapFailed
    }
    do {
      try files.moveItem(at: replacement, to: installed)
    } catch {
      try? files.moveItem(at: backup, to: installed)
      throw UpdateInstallError.swapFailed
    }
    do {
      try files.removeItem(at: backup)
    } catch {
      Self.logger.error("Could not delete the old bundle: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func requireReplaceable(installed: URL, parent: URL) throws {
    let isTranslocated = installed.path.contains("/AppTranslocation/")
    let isReadOnlyVolume =
      (try? parent.resourceValues(forKeys: [.volumeIsReadOnlyKey]).volumeIsReadOnly) == true
    let isWritable = FileManager.default.isWritableFile(atPath: parent.path)
    guard !isTranslocated, !isReadOnlyVolume, isWritable else {
      throw UpdateInstallError.needsApplicationsFolder
    }
  }
}
