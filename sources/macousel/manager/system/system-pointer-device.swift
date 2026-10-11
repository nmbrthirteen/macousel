import AppKit
import Carbon.HIToolbox
import WindowSystem

final class SystemPointerDevice: PointerDevice {
  private let tap: InputEventTap
  private let movement = PointerMonitor()
  private let keys = GlobalEventMonitor(matching: .keyDown)

  init(tap: InputEventTap) {
    self.tap = tap
  }

  var location: CGPoint { Pointer.location }

  var isPrimaryButtonDown: Bool { Pointer.isPrimaryButtonDown }

  func warp(to point: CGPoint) {
    Pointer.warp(to: point)
  }

  func windowID(at point: CGPoint) -> CGWindowID? {
    Pointer.windowID(at: point)
  }

  func serverBounds(of window: CGWindowID) -> CGRect? {
    Pointer.bounds(ofWindow: window)
  }

  func startObservingMovement(_ handler: @escaping (CGPoint) -> Void) {
    movement.onMove = handler
    movement.start()
  }

  func stopObservingMovement() {
    movement.stop()
  }

  func startObservingPrimaryButton(_ handler: @escaping (PrimaryButtonEvent) -> Void) {
    tap.onMouse = { event in
      switch event.kind {
      case .pressed: handler(.pressed(at: event.location))
      case .dragged: handler(.dragged)
      case .released: handler(.released)
      }
    }
    _ = tap.start()
  }

  func stopObservingPrimaryButton() {
    tap.onMouse = nil
    tap.stop()
  }

  func startObservingEscape(_ handler: @escaping () -> Void) {
    keys.start { event in
      if event.keyCode == UInt16(kVK_Escape) { handler() }
    }
  }

  func stopObservingEscape() {
    keys.stop()
  }
}
