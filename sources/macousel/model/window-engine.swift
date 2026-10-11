nonisolated enum WindowEngine: String, Codable, CaseIterable, Sendable {
  case paneru, builtIn

  static let preferred = WindowEngine.paneru

  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = WindowEngine(rawValue: raw) ?? Self.preferred
  }

  var title: String {
    switch self {
    case .paneru: "Paneru"
    case .builtIn: "Built-in"
    }
  }

  var summary: String {
    switch self {
    case .paneru: "Paneru is an open-source engine that runs next to Macousel and moves your windows."
    case .builtIn: "The built-in engine is Macousel's own Swift code and adds drag to rearrange, the scratchpad, and per-display switches."
    }
  }
}
