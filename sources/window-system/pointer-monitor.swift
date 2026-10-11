import AppKit

public final class PointerMonitor {
  private static let minimumInterval: TimeInterval = 1.0 / 30

  public var onMove: ((CGPoint) -> Void)?

  private var monitor: Any?
  private var lastTimestamp: TimeInterval = 0

  public init() {}

  public func start() {
    guard monitor == nil else { return }
    monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
      let timestamp = event.timestamp
      MainActor.assumeIsolated { self?.handle(timestamp: timestamp) }
    }
  }

  public func stop() {
    if let monitor { NSEvent.removeMonitor(monitor) }
    monitor = nil
  }

  private func handle(timestamp: TimeInterval) {
    guard NSEvent.pressedMouseButtons == 0,
      timestamp - lastTimestamp >= Self.minimumInterval
    else { return }
    lastTimestamp = timestamp
    onMove?(Pointer.location)
  }
}
