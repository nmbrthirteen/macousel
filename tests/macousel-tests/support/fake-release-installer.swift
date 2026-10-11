import Foundation

@testable import Macousel

@MainActor
final class FakeReleaseInstaller: ReleaseInstalling {
  var prepareError: UpdateInstallError?
  var applyError: UpdateInstallError?
  private(set) var preparedReleases: [Release] = []
  private(set) var appliedUpdates: [PreparedUpdate] = []

  func prepare(_ release: Release) async throws -> PreparedUpdate {
    preparedReleases.append(release)
    if let prepareError { throw prepareError }
    return PreparedUpdate(
      bundleURL: URL(fileURLWithPath: "/tmp/new/Macousel.app"),
      workDirectory: URL(fileURLWithPath: "/tmp/new"))
  }

  func apply(_ update: PreparedUpdate) throws {
    appliedUpdates.append(update)
    if let applyError { throw applyError }
  }
}
