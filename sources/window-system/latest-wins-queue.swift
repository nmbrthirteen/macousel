import CoreGraphics
import Foundation
import os

nonisolated final class LatestWinsQueue<Request: Sendable>: Sendable {
  private struct State: Sendable {
    var pending: [pid_t: [CGWindowID: Request]] = [:]
    var queues: [pid_t: DispatchQueue] = [:]
    var running: Set<pid_t> = []
    var bursting: Set<pid_t> = []
    var generation: [pid_t: Int] = [:]
  }

  private enum Step {
    case work(CGWindowID, Request)
    case done(generation: Int, queue: DispatchQueue?)
  }

  private let state = OSAllocatedUnfairLock(initialState: State())
  private let apply: @Sendable (CGWindowID, Request) -> Void
  private let beginBurst: @Sendable (pid_t) -> Void
  private let endBurst: @Sendable (pid_t) -> Void
  private let release: @Sendable (pid_t) -> Void
  private let quietDelay: TimeInterval
  private let idleDelay: TimeInterval
  private let flushTimeout: TimeInterval

  init(
    quietDelay: TimeInterval = 0.3,
    idleDelay: TimeInterval = 30,
    flushTimeout: TimeInterval = 1,
    apply: @escaping @Sendable (CGWindowID, Request) -> Void,
    beginBurst: @escaping @Sendable (pid_t) -> Void,
    endBurst: @escaping @Sendable (pid_t) -> Void,
    release: @escaping @Sendable (pid_t) -> Void
  ) {
    self.quietDelay = quietDelay
    self.idleDelay = idleDelay
    self.flushTimeout = flushTimeout
    self.apply = apply
    self.beginBurst = beginBurst
    self.endBurst = endBurst
    self.release = release
  }

  var isIdle: Bool {
    state.withLock { $0.running.isEmpty && $0.pending.isEmpty }
  }

  func hasWork(for pid: pid_t) -> Bool {
    state.withLock { $0.running.contains(pid) }
  }

  func afterPending(_ pid: pid_t, _ work: @escaping @Sendable () -> Void) {
    guard let queue = state.withLock({ $0.queues[pid] }) else {
      work()
      return
    }
    queue.async(execute: work)
  }

  func submit(_ request: Request, window: CGWindowID, pid: pid_t) {
    let queue = state.withLock { state -> DispatchQueue? in
      state.pending[pid, default: [:]][window] = request
      guard state.running.insert(pid).inserted else { return nil }
      if let queue = state.queues[pid] { return queue }
      let queue = DispatchQueue(
        label: "dev.macousel.frame-applier.\(pid)", qos: .userInteractive)
      state.queues[pid] = queue
      return queue
    }
    queue?.async { self.drain(pid) }
  }

  func forget(_ window: CGWindowID) {
    state.withLock { state in
      for pid in Array(state.pending.keys) {
        state.pending[pid]?[window] = nil
        if state.pending[pid]?.isEmpty == true { state.pending[pid] = nil }
      }
    }
  }

  // The caller restores windows next and must not race a placement, so this waits for the
  // queues to drain. All queues drain at once, and a hung app holds the caller for at most
  // the timeout.
  func flush() {
    let queues = state.withLock { Array($0.queues) }
    let group = DispatchGroup()
    for (pid, queue) in queues { queue.async(group: group) { self.finish(pid) } }
    _ = group.wait(timeout: .now() + flushTimeout)
  }

  func forget(pid: pid_t) {
    state.withLock { state in
      state.pending[pid] = nil
      guard !state.running.contains(pid) else { return }
      state.queues[pid] = nil
      state.bursting.remove(pid)
      state.generation[pid] = nil
    }
  }

  private func finish(_ pid: pid_t) {
    let burstWasOpen = state.withLock { state -> Bool? in
      guard !state.running.contains(pid), state.pending[pid] == nil else { return nil }
      return state.bursting.remove(pid) != nil
    }
    guard let burstWasOpen else { return }
    if burstWasOpen { endBurst(pid) }
    release(pid)
  }

  private func drain(_ pid: pid_t) {
    if state.withLock({ $0.bursting.insert(pid).inserted }) { beginBurst(pid) }
    while true {
      let step = state.withLock { state -> Step in
        if let (window, request) = state.pending[pid]?.first {
          state.pending[pid]?[window] = nil
          if state.pending[pid]?.isEmpty == true { state.pending[pid] = nil }
          return .work(window, request)
        }
        state.running.remove(pid)
        let generation = (state.generation[pid] ?? 0) + 1
        state.generation[pid] = generation
        return .done(generation: generation, queue: state.queues[pid])
      }
      switch step {
      case .work(let window, let request):
        apply(window, request)
      case .done(let generation, let queue):
        guard let queue else { return }
        queue.asyncAfter(deadline: .now() + quietDelay) {
          self.endBurstIfQuiet(pid, generation: generation)
        }
        queue.asyncAfter(deadline: .now() + idleDelay) {
          self.releaseIfIdle(pid, generation: generation)
        }
        return
      }
    }
  }

  private func endBurstIfQuiet(_ pid: pid_t, generation: Int) {
    let quiet = state.withLock { state in
      state.generation[pid] == generation && !state.running.contains(pid)
        && state.bursting.remove(pid) != nil
    }
    if quiet { endBurst(pid) }
  }

  private func releaseIfIdle(_ pid: pid_t, generation: Int) {
    let idle = state.withLock { state in
      state.generation[pid] == generation && !state.running.contains(pid)
        && !state.bursting.contains(pid)
    }
    if idle { release(pid) }
  }
}
