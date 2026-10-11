extension MenuBarIndicator {
  var title: String {
    switch self {
    case .icon: "Icon only"
    case .position: "Position on the strip"
    case .pages: "Pages"
    case .count: "Column number"
    }
  }
}
