import AppKit

final class GlobalEventMonitor {
  struct Event {
    var keyCode: UInt16
  }

  private let mask: NSEvent.EventTypeMask
  private let minimumInterval: TimeInterval
  private var token: Any?
  private var lastTimestamp: TimeInterval = 0

  init(matching mask: NSEvent.EventTypeMask, minimumInterval: TimeInterval = 0) {
    self.mask = mask
    self.minimumInterval = minimumInterval
  }

  func start(_ handler: @escaping (Event) -> Void) {
    stop()
    token = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
      let timestamp = event.timestamp
      let keyCode = event.keyCode
      MainActor.assumeIsolated {
        guard let self, timestamp - self.lastTimestamp >= self.minimumInterval else { return }
        self.lastTimestamp = timestamp
        handler(Event(keyCode: keyCode))
      }
    }
  }

  func stop() {
    if let token { NSEvent.removeMonitor(token) }
    token = nil
  }
}
