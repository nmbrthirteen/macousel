import StripCore

enum AnimationSpeed: String, Codable, CaseIterable, Sendable {
  case off, fast, standard, relaxed

  var title: String {
    switch self {
    case .off: "Off"
    case .fast: "Fast"
    case .standard: "Standard"
    case .relaxed: "Relaxed"
    }
  }

  var springResponse: Double? {
    switch self {
    case .off: nil
    case .fast: 0.25
    case .standard: MotionField.standardResponse
    case .relaxed: 0.42
    }
  }
}
