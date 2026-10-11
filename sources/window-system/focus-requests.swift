import os

nonisolated final class FocusRequests: Sendable {
  struct Request: Sendable {
    let sequence: Int
    let usesWindowServer: Bool
  }

  private struct State: Sendable {
    var latestSequence = 0
    var usesWindowServer = WindowServerFocus.shared.isAvailable
  }

  private static let logger = Logger(subsystem: "dev.macousel.app", category: "focus")

  private let state = OSAllocatedUnfairLock(initialState: State())

  func begin() -> Request {
    state.withLock { state in
      state.latestSequence += 1
      return Request(sequence: state.latestSequence, usesWindowServer: state.usesWindowServer)
    }
  }

  func isLatest(_ request: Request) -> Bool {
    state.withLock { $0.latestSequence == request.sequence }
  }

  func disableWindowServer() {
    state.withLock { $0.usesWindowServer = false }
    Self.logger.notice("Window server focus did not take effect, using app activation")
  }
}
