import CoreGraphics
import os

nonisolated final class ProbeBatch: Sendable {
  private struct State: Sendable {
    var facts: [CGWindowID: WindowFacts] = [:]
    var focusedWindow: CGWindowID?
    var waiting: [pid_t: [CGWindowID]]
    var isDelivered = false

    var result: WindowProbeResult {
      WindowProbeResult(facts: facts, focusedWindow: focusedWindow)
    }
  }

  private let state: OSAllocatedUnfairLock<State>
  private let deliver: @Sendable (WindowProbeResult) -> Void

  init(waiting: [pid_t: [CGWindowID]], deliver: @escaping @Sendable (WindowProbeResult) -> Void) {
    state = OSAllocatedUnfairLock(initialState: State(waiting: waiting))
    self.deliver = deliver
  }

  func finish(
    pid: pid_t, facts: [CGWindowID: WindowFacts], focusedWindow: CGWindowID?
  ) {
    let result = state.withLock { state -> WindowProbeResult? in
      guard !state.isDelivered, state.waiting.removeValue(forKey: pid) != nil else { return nil }
      state.facts.merge(facts) { _, read in read }
      if let focusedWindow { state.focusedWindow = focusedWindow }
      guard state.waiting.isEmpty else { return nil }
      state.isDelivered = true
      return state.result
    }
    if let result { deliver(result) }
  }

  func expire() {
    let result = state.withLock { state -> WindowProbeResult? in
      guard !state.isDelivered else { return nil }
      state.isDelivered = true
      for window in state.waiting.values.joined() { state.facts[window] = .unanswered }
      state.waiting = [:]
      return state.result
    }
    if let result { deliver(result) }
  }
}
