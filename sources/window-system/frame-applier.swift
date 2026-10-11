import CoreGraphics
import Dispatch

public final class FrameApplier {
  private let queue: LatestWinsQueue<PlacementRequest>
  private let worker: PlacementWorker

  public init() {
    let worker = PlacementWorker(messagingTimeout: WindowTracker.messagingTimeout)
    self.worker = worker
    queue = LatestWinsQueue(
      apply: { worker.apply($0, $1) },
      beginBurst: { worker.beginBurst(of: $0) },
      endBurst: { worker.endBurst(of: $0) },
      release: { worker.restoreEnhancedInterface(of: $0) })
  }

  public func submit(_ frame: CGRect, for window: ManagedWindow) {
    queue.submit(
      PlacementRequest(
        pid: window.pid, bundleIdentifier: window.bundleIdentifier,
        element: ThreadSafeAXElement(element: window.element), frame: frame),
      window: window.id, pid: window.pid)
  }

  public func afterPlacement(
    of window: ManagedWindow, within timeout: Duration, _ action: @escaping () -> Void
  ) {
    guard queue.hasWork(for: window.pid) else {
      action()
      return
    }
    let once = PlacementWaiter(action)
    queue.afterPending(window.pid) {
      DispatchQueue.main.async { MainActor.assumeIsolated { once.fire() } }
    }
    let delay = DispatchTimeInterval.milliseconds(Int(timeout.fractionalMilliseconds))
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      MainActor.assumeIsolated { once.fire() }
    }
  }

  public var isIdle: Bool {
    queue.isIdle
  }

  public func isSlow(pid: pid_t, bundleIdentifier: String?) -> Bool {
    worker.isSlow(pid, bundleIdentifier: bundleIdentifier)
  }

  public func seedSlowApps(_ bundleIdentifiers: Set<String>) {
    worker.seedSlowApps(bundleIdentifiers)
  }

  public func observeSlowChanges(_ observer: @escaping @Sendable (String, Bool) -> Void) {
    worker.observeSlowChanges(observer)
  }

  public func flush() {
    queue.flush()
  }

  public func forget(_ window: CGWindowID) {
    queue.forget(window)
    worker.forget(window)
  }
}
