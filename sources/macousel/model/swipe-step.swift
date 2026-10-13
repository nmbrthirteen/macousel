enum SwipeStep: String, Codable, CaseIterable, Sendable {
  case column, free

  var title: String {
    switch self {
    case .column: "One column at a time"
    case .free: "Freely"
    }
  }
}
