import AppKit

final class GlobalEventMonitor {
  struct Event {
    var keyCode: UInt16
  }

  private let mask: NSEvent.EventTypeMask
  private var token: Any?

  init(matching mask: NSEvent.EventTypeMask) {
    self.mask = mask
  }

  func start(_ handler: @escaping (Event) -> Void) {
    stop()
    token = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
      let keyCode = event.keyCode
      MainActor.assumeIsolated { handler(Event(keyCode: keyCode)) }
    }
  }

  func stop() {
    if let token { NSEvent.removeMonitor(token) }
    token = nil
  }
}
