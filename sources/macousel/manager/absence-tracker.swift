import StripCore

struct AbsenceTracker {
  enum Verdict {
    case present
    case excluded
    case offScreen
    case closed
  }

  static let passesBeforeRemoval = 2

  private var missedPasses: [WindowID: Int] = [:]

  mutating func removals(among members: Set<WindowID>, verdict: (WindowID) -> Verdict)
    -> Set<WindowID>
  {
    var removals: Set<WindowID> = []
    var stillMissing: [WindowID: Int] = [:]
    for member in members {
      switch verdict(member) {
      case .present:
        continue
      case .excluded, .closed:
        removals.insert(member)
      case .offScreen:
        let missed = (missedPasses[member] ?? 0) + 1
        if missed >= Self.passesBeforeRemoval {
          removals.insert(member)
        } else {
          stillMissing[member] = missed
        }
      }
    }
    missedPasses = stillMissing
    return removals
  }
}
