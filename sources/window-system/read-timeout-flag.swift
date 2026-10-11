import os

nonisolated final class ReadTimeoutFlag: Sendable {
  private let timedOut = OSAllocatedUnfairLock(initialState: false)

  func note() {
    timedOut.withLock { $0 = true }
  }

  func take() -> Bool {
    timedOut.withLock { timedOut in
      defer { timedOut = false }
      return timedOut
    }
  }
}
