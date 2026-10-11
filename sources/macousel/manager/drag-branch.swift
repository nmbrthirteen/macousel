enum DragBranch: Equatable {
  case resizedWidth
  case resizedHeight
  case resizedWidthAndHeight
  case stacked(above: Bool)
  case reordered(column: Int)
  case movedToDisplay
  case returnedToSlot
  case cancelled

  var logName: String {
    switch self {
    case .resizedWidth: "resized width"
    case .resizedHeight: "resized height"
    case .resizedWidthAndHeight: "resized width and height"
    case .stacked(let above): above ? "stacked above a target" : "stacked below a target"
    case .reordered(let column): "reordered to column \(column)"
    case .movedToDisplay: "moved to another display"
    case .returnedToSlot: "returned to its slot"
    case .cancelled: "cancelled"
    }
  }

  var targetKind: String {
    switch self {
    case .stacked: "stack"
    case .reordered: "column"
    case .movedToDisplay: "display"
    default: "none"
    }
  }
}
