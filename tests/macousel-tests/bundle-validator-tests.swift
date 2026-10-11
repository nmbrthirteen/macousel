import Foundation
import Testing

@testable import Macousel

@MainActor
struct BundleValidatorTests {
  private func validator(
    running: String = "0.1.0", signature: Bool = true
  ) throws -> BundleValidator {
    BundleValidator(
      runningIdentifier: "dev.macousel.app", runningVersion: try #require(AppVersion(running)),
      verifySignature: { _ in signature })
  }

  @Test func acceptsANewerBundleWithTheSameIdentifierAndAValidSignature() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let bundle = try directory.makeBundle(version: "0.2.0")

    let validated = try await validator().validate(unpackedIn: directory.url)

    #expect(validated == bundle)
  }

  @Test func rejectsADifferentBundleIdentifier() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    _ = try directory.makeBundle(identifier: "com.example.other")
    let validator = try validator()

    await #expect(throws: UpdateInstallError.wrongIdentifier) {
      try await validator.validate(unpackedIn: directory.url)
    }
  }

  @Test(arguments: ["0.1.0", "0.0.9", "0.1"])
  func rejectsAVersionThatIsNotNewer(version: String) async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    _ = try directory.makeBundle(version: version)
    let validator = try validator(running: "0.1.0")

    await #expect(throws: UpdateInstallError.notNewer) {
      try await validator.validate(unpackedIn: directory.url)
    }
  }

  @Test func rejectsABundleThatFailsTheSignatureCheck() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    _ = try directory.makeBundle()
    let validator = try validator(signature: false)

    await #expect(throws: UpdateInstallError.invalidSignature) {
      try await validator.validate(unpackedIn: directory.url)
    }
  }

  @Test func rejectsAnArchiveWhoseAppHasAnotherName() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    _ = try directory.makeBundle(named: "Other.app")
    let validator = try validator()

    await #expect(throws: UpdateInstallError.missingApp) {
      try await validator.validate(unpackedIn: directory.url)
    }
  }
}
