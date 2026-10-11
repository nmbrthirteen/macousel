import Foundation
import os

nonisolated final class FocusRequests: Sendable {
  struct Request: Sendable {
    let sequence: Int
    let usesWindowServer: Bool
  }

  private struct State: Sendable {
    var latestSequence = 0
    var usesWindowServer = WindowServerFocus.shared.isAvailable
    var consecutiveMisses = 0
    var disabledAt: ContinuousClock.Instant?
  }

  private static let logger = Logger(subsystem: "dev.macousel.app", category: "focus")
  private static let missesBeforeDisabling = 3
  private static let rearmDelay = Duration.seconds(60)

  private let state = OSAllocatedUnfairLock(initialState: State())

  func begin() -> Request {
    state.withLock { state in
      state.latestSequence += 1
      if let disabledAt = state.disabledAt, disabledAt.duration(to: .now) >= Self.rearmDelay {
        state.disabledAt = nil
        state.consecutiveMisses = 0
        state.usesWindowServer = WindowServerFocus.shared.isAvailable
      }
      return Request(sequence: state.latestSequence, usesWindowServer: state.usesWindowServer)
    }
  }

  func isLatest(_ request: Request) -> Bool {
    state.withLock { $0.latestSequence == request.sequence }
  }

  func recordHit() {
    state.withLock { $0.consecutiveMisses = 0 }
  }

  func recordMiss() {
    let disabled = state.withLock { state -> Bool in
      state.consecutiveMisses += 1
      guard state.consecutiveMisses >= Self.missesBeforeDisabling, state.usesWindowServer
      else { return false }
      state.usesWindowServer = false
      state.disabledAt = .now
      return true
    }
    if disabled {
      Self.logger.notice("Window server focus missed repeatedly, using app activation")
    }
  }
}
