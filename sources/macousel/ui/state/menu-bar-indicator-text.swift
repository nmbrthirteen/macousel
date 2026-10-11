extension MenuBarIndicator {
  var title: String {
    switch self {
    case .icon: "Icon only"
    case .position: "Position on the strip"
    case .count: "Column number"
    }
  }
}
