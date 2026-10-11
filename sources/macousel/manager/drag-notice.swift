enum DragNotice {
  case draggedEvent
  case poll

  var logName: String {
    switch self {
    case .draggedEvent: "dragged event"
    case .poll: "poll"
    }
  }
}
