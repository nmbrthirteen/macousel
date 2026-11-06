// Every capture and every close carries a generation, so a capture or a landing that finishes
// after the overview changed course is ignored instead of showing or hiding the wrong thing.
struct OverviewTransition {
  enum Stage: Equatable {
    case closed, capturing, open, closing
  }

  enum Opening: Equatable {
    case capture(generation: Int)
    case update
    case expand
  }

  enum Closing: Equatable {
    case none
    case abandon
    case collapse(generation: Int)
  }

  private(set) var stage = Stage.closed
  private var generation = 0

  mutating func open() -> Opening {
    switch stage {
    case .closed:
      generation += 1
      stage = .capturing
      return .capture(generation: generation)
    case .capturing, .open:
      return .update
    case .closing:
      generation += 1
      stage = .open
      return .expand
    }
  }

  mutating func captured(_ capture: Int) -> Bool {
    guard stage == .capturing, capture == generation else { return false }
    stage = .open
    return true
  }

  mutating func close() -> Closing {
    switch stage {
    case .closed, .closing:
      return .none
    case .capturing:
      generation += 1
      stage = .closed
      return .abandon
    case .open:
      generation += 1
      stage = .closing
      return .collapse(generation: generation)
    }
  }

  mutating func landed(_ close: Int) -> Bool {
    guard stage == .closing, close == generation else { return false }
    stage = .closed
    return true
  }
}
