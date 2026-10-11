import CoreGraphics

nonisolated enum GroupReading {
  struct Outcome: Sendable {
    var facts: [CGWindowID: WindowFacts] = [:]
    var focusedWindow: CGWindowID?
  }

  static func run(items: [WindowReadItem], focus: FocusReadItem?) -> Outcome {
    var outcome = Outcome()
    outcome.focusedWindow = focus?.read()
    for (index, item) in items.enumerated() {
      let facts = item.read()
      outcome.facts[item.id] = facts
      guard facts.timedOut else { continue }
      for skipped in items[(index + 1)...] { outcome.facts[skipped.id] = .unanswered }
      break
    }
    return outcome
  }
}
