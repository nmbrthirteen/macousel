import Foundation

struct BundleValidator {
  typealias SignatureCheck = @Sendable (URL) async -> Bool

  static let bundleName = "Macousel.app"

  static let codesign: SignatureCheck = { bundle in
    let status = try? await ProcessRunner.run("/usr/bin/codesign", ["--verify", "--deep", bundle.path])
    return status == 0
  }

  let runningIdentifier: String
  let runningVersion: AppVersion
  let verifySignature: SignatureCheck

  init(
    runningIdentifier: String, runningVersion: AppVersion,
    verifySignature: @escaping SignatureCheck = BundleValidator.codesign
  ) {
    self.runningIdentifier = runningIdentifier
    self.runningVersion = runningVersion
    self.verifySignature = verifySignature
  }

  func validate(unpackedIn directory: URL) async throws -> URL {
    let bundleURL = directory.appendingPathComponent(Self.bundleName, isDirectory: true)
    guard let bundle = Bundle(url: bundleURL) else { throw UpdateInstallError.missingApp }
    let info = BundleInfo(bundle: bundle)
    guard info.identifier == runningIdentifier else { throw UpdateInstallError.wrongIdentifier }
    guard let version = info.version, version > runningVersion else {
      throw UpdateInstallError.notNewer
    }
    guard await verifySignature(bundleURL) else { throw UpdateInstallError.invalidSignature }
    return bundleURL
  }
}
