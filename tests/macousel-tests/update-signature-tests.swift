import CryptoKit
import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct UpdateSignatureTests {
  private let key = Curve25519.Signing.PrivateKey()
  private let archive = Data("pretend zip bytes".utf8)

  private var verifier: UpdateSignatureVerifier {
    UpdateSignatureVerifier(publicKeyBase64: key.publicKey.rawRepresentation.base64EncodedString())
  }

  private func signature(of data: Data, using key: Curve25519.Signing.PrivateKey? = nil) throws
    -> Data
  {
    Data(try (key ?? self.key).signature(for: data).base64EncodedString().utf8)
  }

  @Test func acceptsASignatureMadeOverTheExactArchiveBytes() throws {
    #expect(verifier.isValid(signatureBase64: try signature(of: archive), for: archive))
  }

  @Test func acceptsASignatureFileWithATrailingNewline() throws {
    let signed = try signature(of: archive) + Data("\n".utf8)

    #expect(verifier.isValid(signatureBase64: signed, for: archive))
  }

  @Test func rejectsATamperedArchive() throws {
    let signed = try signature(of: archive)
    var tampered = archive
    tampered[0] ^= 1

    #expect(!verifier.isValid(signatureBase64: signed, for: tampered))
  }

  @Test func rejectsASignatureFromAnotherKey() throws {
    let stranger = Curve25519.Signing.PrivateKey()

    #expect(
      !verifier.isValid(signatureBase64: try signature(of: archive, using: stranger), for: archive))
  }

  @Test(arguments: ["", "not base64!!", "AAAA"])
  func rejectsAMalformedSignature(text: String) {
    #expect(!verifier.isValid(signatureBase64: Data(text.utf8), for: archive))
  }

  @Test func rejectsEverythingWhenTheEmbeddedKeyIsMalformed() throws {
    let broken = UpdateSignatureVerifier(publicKeyBase64: "AAAA")

    #expect(!broken.isValid(signatureBase64: try signature(of: archive), for: archive))
  }

  @Test func theEmbeddedPublicKeyIsAValidEd25519Key() throws {
    let raw = try #require(Data(base64Encoded: UpdateSigningKey.publicKeyBase64))

    #expect(raw.count == 32)
    _ = try Curve25519.Signing.PublicKey(rawRepresentation: raw)
  }

  @Test func verifiesFilesOnDisk() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let archiveFile = directory.url.appendingPathComponent("Macousel.zip")
    let signatureFile = directory.url.appendingPathComponent("Macousel.zip.sig")
    try archive.write(to: archiveFile)
    try signature(of: archive).write(to: signatureFile)

    #expect(verifier.isValid(signatureFile: signatureFile, archiveFile: archiveFile))
    try Data("tampered".utf8).write(to: archiveFile)
    #expect(!verifier.isValid(signatureFile: signatureFile, archiveFile: archiveFile))
  }

  private func installer(
    serving archiveBytes: Data, signatureBytes: Data, root: URL
  ) -> UpdateInstaller {
    let downloader = ArchiveDownloader(download: { url in
      let file = root.appendingPathComponent("download-\(UUID().uuidString)")
      try (url.lastPathComponent.hasSuffix(".sig") ? signatureBytes : archiveBytes).write(to: file)
      return (file, url)
    })
    return UpdateInstaller(
      runningBundleURL: root.appendingPathComponent("Macousel.app"), downloader: downloader,
      validator: BundleValidator(
        runningIdentifier: "dev.macousel.app", runningVersion: .zero,
        verifySignature: { _ in true }),
      verifier: verifier, workRoot: root.appendingPathComponent("work"))
  }

  @Test func theInstallerRefusesAnArchiveWhoseSignatureDoesNotVerify() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let signed = try signature(of: archive)
    let installer = installer(
      serving: Data("tampered".utf8), signatureBytes: signed, root: directory.url)

    await #expect(throws: UpdateInstallError.unverifiedUpdate) {
      try await installer.prepare(try ReleaseJSON.release())
    }
    let leftovers = try? FileManager.default.contentsOfDirectory(
      atPath: directory.url.appendingPathComponent("work").path)
    #expect(leftovers?.isEmpty ?? true)
  }

  @Test func theInstallerUnpacksOnlyAfterTheSignatureVerifies() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let installer = installer(
      serving: archive, signatureBytes: try signature(of: archive), root: directory.url)

    await #expect(throws: UpdateInstallError.unpackFailed) {
      try await installer.prepare(try ReleaseJSON.release())
    }
  }

  @Test func theUnverifiedMessageTellsTheUserWhatToDo() {
    #expect(
      UpdateInstallError.unverifiedUpdate.message
        == "This update could not be verified, so it was not installed. Download it from the releases page if you trust it."
    )
  }
}
