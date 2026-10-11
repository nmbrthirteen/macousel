import os

nonisolated final class SwipeFrameGate: Sendable {
  private struct State: Sendable {
    var fingerCount = 3
    var isEngaged = false
  }

  private let state = OSAllocatedUnfairLock(initialState: State())

  var fingerCount: Int {
    get { state.withLock { $0.fingerCount } }
    set { state.withLock { $0.fingerCount = newValue } }
  }

  func admits(fingers: Int) -> Bool {
    state.withLock { state in
      let matches = fingers == state.fingerCount
      let admitted = matches || state.isEngaged
      state.isEngaged = matches
      return admitted
    }
  }

  func reset() {
    state.withLock { $0.isEngaged = false }
  }
}
