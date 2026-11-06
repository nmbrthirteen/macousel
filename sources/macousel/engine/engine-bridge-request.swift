import Foundation

nonisolated enum EngineBridgeRequest: Equatable, Sendable {
  case snapshot
  case command([String])

  private struct Line: Encodable {
    var id: Int
    var request: String
    var words: [String]?
  }

  func line(id: Int) throws -> Data {
    let line =
      switch self {
      case .snapshot: Line(id: id, request: "snapshot")
      case .command(let words): Line(id: id, request: "command", words: words)
      }
    return try JSONEncoder().encode(line) + Data("\n".utf8)
  }
}
