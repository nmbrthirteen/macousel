enum DragBranch: Equatable {
  case resizedWidth
  case resizedHeight
  case resizedWidthAndHeight
  case stacked(above: Bool)
  case reordered(column: Int)
  case movedToDisplay

  var logName: String {
    switch self {
    case .resizedWidth: "resized width"
    case .resizedHeight: "resized height"
    case .resizedWidthAndHeight: "resized width and height"
    case .stacked(let above): above ? "stacked above a target" : "stacked below a target"
    case .reordered(let column): "reordered to column \(column)"
    case .movedToDisplay: "moved to another display"
    }
  }

  var reportsPointerPosition: Bool {
    switch self {
    case .reordered, .movedToDisplay: true
    default: false
    }
  }
}
