import CryptoKit
import Foundation

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("error: \(message)\n".utf8))
  exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
  fail("usage: swift scripts/sign-update.swift <archive> <output>")
}
guard let encodedKey = ProcessInfo.processInfo.environment["UPDATE_SIGNING_KEY"],
  !encodedKey.isEmpty
else {
  fail("UPDATE_SIGNING_KEY is not set.")
}
guard let keyData = Data(base64Encoded: encodedKey.trimmingCharacters(in: .whitespacesAndNewlines)),
  let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
else {
  fail("UPDATE_SIGNING_KEY is not a base64 Ed25519 private key.")
}
guard let archive = FileManager.default.contents(atPath: arguments[1]) else {
  fail("Could not read \(arguments[1]).")
}
do {
  let signature = try key.signature(for: archive)
  try Data(signature.base64EncodedString().utf8).write(to: URL(fileURLWithPath: arguments[2]))
} catch {
  fail("Could not sign the archive: \(error.localizedDescription)")
}
