import CoreGraphics

public final class FrameApplier {
  private let queue: LatestWinsQueue<PlacementRequest>
  private let worker: PlacementWorker

  public init() {
    let worker = PlacementWorker(messagingTimeout: WindowTracker.messagingTimeout)
    self.worker = worker
    queue = LatestWinsQueue(
      apply: { worker.apply($0, $1) },
      beginBurst: { worker.beginBurst(of: $0) },
      endBurst: { worker.endBurst(of: $0) })
  }

  public func submit(_ frame: CGRect, for window: ManagedWindow) {
    queue.submit(
      PlacementRequest(
        pid: window.pid, element: ThreadSafeAXElement(element: window.element), frame: frame),
      window: window.id, pid: window.pid)
  }

  public var isIdle: Bool {
    queue.isIdle
  }

  public var slowestRecentApplySeconds: Double {
    worker.slowestRecentAverage(busy: queue.busyPIDs)
  }

  public func flush() {
    queue.flush()
  }

  public func forget(_ window: CGWindowID) {
    queue.forget(window)
    worker.forget(window)
  }
}
