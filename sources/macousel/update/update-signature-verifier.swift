import CryptoKit
import Foundation

nonisolated struct UpdateSignatureVerifier {
  private let publicKey: Curve25519.Signing.PublicKey?

  init(publicKeyBase64: String = UpdateSigningKey.publicKeyBase64) {
    publicKey = Data(base64Encoded: publicKeyBase64).flatMap {
      try? Curve25519.Signing.PublicKey(rawRepresentation: $0)
    }
  }

  func isValid(signatureBase64: Data, for archive: Data) -> Bool {
    let text = String(decoding: signatureBase64, as: UTF8.self)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let publicKey, let signature = Data(base64Encoded: text) else { return false }
    return publicKey.isValidSignature(signature, for: archive)
  }

  func isValid(signatureFile: URL, archiveFile: URL) -> Bool {
    guard let signature = try? Data(contentsOf: signatureFile),
      let archive = try? Data(contentsOf: archiveFile, options: .mappedIfSafe)
    else { return false }
    return isValid(signatureBase64: signature, for: archive)
  }
}
