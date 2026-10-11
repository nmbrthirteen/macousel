import Foundation
import Testing

@testable import Macousel

@MainActor
struct BundleSwapperTests {
  private func installedBundle(
    in directory: TemporaryDirectory, under parentName: String = "Applications"
  ) throws -> URL {
    let parent = directory.url.appendingPathComponent(parentName, isDirectory: true)
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    return try directory.makeBundle(in: parent, marker: "old")
  }

  private func newBundle(in directory: TemporaryDirectory) throws -> URL {
    let staging = directory.url.appendingPathComponent("staging", isDirectory: true)
    try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
    return try directory.makeBundle(in: staging, marker: "new")
  }

  @Test func theNewBundleReplacesTheOldOneAndNoBackupRemains() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let installed = try installedBundle(in: directory)
    let replacement = try newBundle(in: directory)

    try BundleSwapper().swap(installed: installed, with: replacement)

    #expect(directory.marker(of: installed) == "new")
    #expect(try directory.entries(in: installed.deletingLastPathComponent()) == ["Macousel.app"])
    #expect(!FileManager.default.fileExists(atPath: replacement.path))
  }

  @Test func aFailingMoveRestoresTheOldBundle() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let installed = try installedBundle(in: directory)
    let missing = directory.url.appendingPathComponent("staging/Macousel.app")

    #expect(throws: UpdateInstallError.swapFailed) {
      try BundleSwapper().swap(installed: installed, with: missing)
    }

    #expect(directory.marker(of: installed) == "old")
    #expect(try directory.entries(in: installed.deletingLastPathComponent()) == ["Macousel.app"])
  }

  @Test func aNonWritableParentFailsWithTheMoveToApplicationsMessage() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let installed = try installedBundle(in: directory)
    let replacement = try newBundle(in: directory)
    let parent = installed.deletingLastPathComponent()
    try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: parent.path)
    defer {
      try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: parent.path)
    }

    #expect(throws: UpdateInstallError.needsApplicationsFolder) {
      try BundleSwapper().swap(installed: installed, with: replacement)
    }

    #expect(directory.marker(of: installed) == "old")
    #expect(
      UpdateInstallError.needsApplicationsFolder.message
        == "Move Macousel to the Applications folder, then update.")
  }

  @Test func aTranslocatedBundleFailsWithTheMoveToApplicationsMessage() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let installed = try installedBundle(in: directory, under: "AppTranslocation/ABC/d")
    let replacement = try newBundle(in: directory)

    #expect(throws: UpdateInstallError.needsApplicationsFolder) {
      try BundleSwapper().swap(installed: installed, with: replacement)
    }

    #expect(directory.marker(of: installed) == "old")
  }
}
