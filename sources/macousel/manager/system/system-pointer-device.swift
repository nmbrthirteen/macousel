import AppKit
import WindowSystem

final class SystemPointerDevice: PointerDevice {
  private let movement = PointerMonitor()
  private var releaseMonitor: Any?

  var location: CGPoint { Pointer.location }

  var isPrimaryButtonDown: Bool { Pointer.isPrimaryButtonDown }

  func warp(to point: CGPoint) {
    Pointer.warp(to: point)
  }

  func windowID(at point: CGPoint) -> CGWindowID? {
    Pointer.windowID(at: point)
  }

  func startObservingMovement(_ handler: @escaping (CGPoint) -> Void) {
    movement.onMove = handler
    movement.start()
  }

  func stopObservingMovement() {
    movement.stop()
  }

  func startObservingPrimaryRelease(_ handler: @escaping () -> Void) {
    guard releaseMonitor == nil else { return }
    releaseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { _ in handler() }
  }

  func stopObservingPrimaryRelease() {
    if let releaseMonitor { NSEvent.removeMonitor(releaseMonitor) }
    releaseMonitor = nil
  }
}
