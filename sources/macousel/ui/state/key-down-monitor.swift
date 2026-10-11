import AppKit

final class KeyDownMonitor {
  private var token: AnyObject?

  func start(_ handler: @escaping (NSEvent) -> NSEvent?) {
    stop()
    token = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handler) as AnyObject?
  }

  func stop() {
    guard let token else { return }
    NSEvent.removeMonitor(token)
    self.token = nil
  }
}
