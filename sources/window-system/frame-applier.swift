import ApplicationServices
import CoreGraphics
import Foundation
import os

nonisolated struct ThreadSafeAXElement: @unchecked Sendable {
  let element: AXUIElement
}

private nonisolated struct Placement: Sendable {
  let element: ThreadSafeAXElement
  let frame: CGRect
}

nonisolated final class LatestWinsQueue<Request: Sendable>: Sendable {
  private struct State: Sendable {
    var pending: [pid_t: [CGWindowID: Request]] = [:]
    var queues: [pid_t: DispatchQueue] = [:]
    var running: Set<pid_t> = []
    var bursting: Set<pid_t> = []
    var generation: [pid_t: Int] = [:]
  }

  private enum Step {
    case work([(CGWindowID, Request)])
    case done(generation: Int, queue: DispatchQueue)
  }

  private let state = OSAllocatedUnfairLock(initialState: State())
  private let apply: @Sendable (CGWindowID, Request) -> Void
  private let beginBurst: @Sendable (pid_t) -> Void
  private let endBurst: @Sendable (pid_t) -> Void
  private let restoreDelay: TimeInterval

  init(
    restoreDelay: TimeInterval = 0.3,
    apply: @escaping @Sendable (CGWindowID, Request) -> Void,
    beginBurst: @escaping @Sendable (pid_t) -> Void,
    endBurst: @escaping @Sendable (pid_t) -> Void
  ) {
    self.restoreDelay = restoreDelay
    self.apply = apply
    self.beginBurst = beginBurst
    self.endBurst = endBurst
  }

  var isIdle: Bool {
    state.withLock { $0.running.isEmpty && $0.pending.isEmpty }
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

  func flush() {
    let queues = state.withLock { Array($0.queues.values) }
    for queue in queues { queue.sync {} }
    let quiet = state.withLock { state -> [pid_t] in
      let quiet = state.bursting.filter { state.pending[$0] == nil && !state.running.contains($0) }
      state.bursting.subtract(quiet)
      return Array(quiet)
    }
    for pid in quiet { endBurst(pid) }
  }

  private func drain(_ pid: pid_t) {
    if state.withLock({ $0.bursting.insert(pid).inserted }) { beginBurst(pid) }
    while true {
      let step = state.withLock { state -> Step in
        if let batch = state.pending.removeValue(forKey: pid), !batch.isEmpty {
          return .work(Array(batch))
        }
        state.running.remove(pid)
        let generation = (state.generation[pid] ?? 0) + 1
        state.generation[pid] = generation
        return .done(generation: generation, queue: state.queues[pid]!)
      }
      switch step {
      case .work(let batch):
        for (window, request) in batch { apply(window, request) }
      case .done(let generation, let queue):
        queue.asyncAfter(deadline: .now() + restoreDelay) {
          self.restoreIfQuiet(pid, generation: generation)
        }
        return
      }
    }
  }

  private func restoreIfQuiet(_ pid: pid_t, generation: Int) {
    let restore = state.withLock { state in
      state.generation[pid] == generation && !state.running.contains(pid)
        && state.bursting.remove(pid) != nil
    }
    if restore { endBurst(pid) }
  }
}

private nonisolated final class PlacementWorker: Sendable {
  private static let enhancedInterface = "AXEnhancedUserInterface"

  private let sizes = OSAllocatedUnfairLock(initialState: [CGWindowID: CGSize]())
  private let suspended = OSAllocatedUnfairLock(initialState: Set<pid_t>())
  private let messagingTimeout: Float

  init(messagingTimeout: Float) {
    self.messagingTimeout = messagingTimeout
  }

  func apply(_ window: CGWindowID, _ placement: Placement) {
    let element = placement.element.element
    let frame = placement.frame
    if sizes.withLock({ $0[window] }) == frame.size {
      element.set(point: frame.origin, for: kAXPositionAttribute)
      return
    }
    let sized = element.set(size: frame.size, for: kAXSizeAttribute)
    element.set(point: frame.origin, for: kAXPositionAttribute)
    element.set(size: frame.size, for: kAXSizeAttribute)
    if sized { sizes.withLock { $0[window] = frame.size } }
  }

  func forget(_ window: CGWindowID) {
    sizes.withLock { $0[window] = nil }
  }

  func disableEnhancedInterface(of pid: pid_t) {
    let app = applicationElement(pid)
    let enhanced: Bool = app.attribute(Self.enhancedInterface) ?? false
    guard enhanced else { return }
    app.set(bool: false, for: Self.enhancedInterface)
    suspended.withLock { _ = $0.insert(pid) }
  }

  func restoreEnhancedInterface(of pid: pid_t) {
    guard suspended.withLock({ $0.remove(pid) != nil }) else { return }
    applicationElement(pid).set(bool: true, for: Self.enhancedInterface)
  }

  private func applicationElement(_ pid: pid_t) -> AXUIElement {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, messagingTimeout)
    return app
  }
}

public final class FrameApplier {
  private let queue: LatestWinsQueue<Placement>
  private let worker: PlacementWorker

  public init() {
    let worker = PlacementWorker(messagingTimeout: WindowTracker.messagingTimeout)
    self.worker = worker
    queue = LatestWinsQueue(
      apply: { worker.apply($0, $1) },
      beginBurst: { worker.disableEnhancedInterface(of: $0) },
      endBurst: { worker.restoreEnhancedInterface(of: $0) })
  }

  public func submit(_ frame: CGRect, for window: ManagedWindow) {
    queue.submit(
      Placement(element: ThreadSafeAXElement(element: window.element), frame: frame),
      window: window.id, pid: window.pid)
  }

  public var isIdle: Bool {
    queue.isIdle
  }

  public func flush() {
    queue.flush()
  }

  public func forget(_ window: CGWindowID) {
    queue.forget(window)
    worker.forget(window)
  }
}
