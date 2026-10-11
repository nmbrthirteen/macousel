import CryptoKit
import Foundation

nonisolated enum TitleDigest {
  static let length = 16

  static func of(_ title: String) -> String {
    let hex = SHA256.hash(data: Data(title.utf8)).map { String(format: "%02x", $0) }.joined()
    return String(hex.prefix(length))
  }
}
