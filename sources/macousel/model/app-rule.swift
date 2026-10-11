import Foundation

struct AppRule: Codable, Equatable, Identifiable {
  enum Behavior: Codable, Equatable {
    case float
    case width(Double)
    case slot(Int)
  }

  var bundleIdentifier: String
  var behavior: Behavior

  var id: String { bundleIdentifier }
}
