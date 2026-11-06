import Foundation
import WindowSystem
import os

// One line from the bridge. A line without an id is an engine event.
nonisolated struct EngineBridgeAnswer: Decodable, Equatable, Sendable {
  var id: Int?
  var error: String?
  var unparsed = false
  var snapshot: EngineSnapshot?

  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()

  static func decode(line: String) -> EngineBridgeAnswer? {
    do {
      return try decoder.decode(EngineBridgeAnswer.self, from: Data(line.utf8))
    } catch {
      logger.error("Could not read an engine bridge line: \(error, privacy: .public)")
      return nil
    }
  }
}

nonisolated extension EngineBridgeAnswer {
  private enum CodingKeys: String, CodingKey {
    case id, error, unparsed, state
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decodeIfPresent(Int.self, forKey: .id)
    error = try values.decodeIfPresent(String.self, forKey: .error)
    unparsed = try values.decodeIfPresent(Bool.self, forKey: .unparsed) ?? false
    guard values.contains(.state) else { return }
    // An unreadable state must still answer its request, or the caller waits out the timeout.
    do {
      snapshot = try EngineSnapshot.Bridged(from: decoder).snapshot
    } catch {
      Self.logger.error("Could not read the bridged engine state: \(error, privacy: .public)")
    }
  }
}
