enum EngineReorderOutcome: Equatable {
  case completed(EngineSnapshot)
  case nothingToDo(EngineSnapshot)
  case aborted(step: String, EngineSnapshot?)
  case busy
  case unavailable

  var snapshot: EngineSnapshot? {
    switch self {
    case .completed(let snapshot), .nothingToDo(let snapshot): snapshot
    case .aborted(_, let snapshot): snapshot
    case .busy, .unavailable: nil
    }
  }
}
