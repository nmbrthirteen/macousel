import StripCore
import os

struct CommandLog {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "commands")

  func performed(
    _ action: Action, outcome: StripCommandOutcome, before: Strip, after: Strip
  ) {
    Self.logger.info(
      """
      \(action.commandName, privacy: .public) \(outcome.logName, privacy: .public): \
      \(before.shapeSummary, privacy: .public) -> \(after.shapeSummary, privacy: .public), \
      focus \(before.focusSummary, privacy: .public) -> \(after.focusSummary, privacy: .public)
      """)
  }

  func closedOverview(before action: Action) {
    Self.logger.info(
      "\(action.commandName, privacy: .public) closed the overview before running")
  }

  func dropped(_ action: Action, because reason: DroppedCommandReason) {
    Self.logger.info(
      "\(action.commandName, privacy: .public) dropped: \(reason.rawValue, privacy: .public)")
  }
}

extension StripCommandOutcome {
  var logName: String {
    switch self {
    case .applied: "applied"
    case .appliedKeepingScroll: "applied keeping scroll"
    case .blockedAtEdge(let side): "blocked at \(side == .left ? "left" : "right") edge"
    case .ignored: "ignored"
    }
  }
}
