import AppKit
import Carbon.HIToolbox
import WindowSystem

final class SystemPointerDevice: PointerDevice {
  private static let draggedInterval: TimeInterval = 1.0 / 60

  private let movement = PointerMonitor()
  private let buttonDown = GlobalEventMonitor(matching: .leftMouseDown)
  private let buttonDragged = GlobalEventMonitor(
    matching: .leftMouseDragged, minimumInterval: SystemPointerDevice.draggedInterval)
  private let buttonUp = GlobalEventMonitor(matching: .leftMouseUp)
  private let keys = GlobalEventMonitor(matching: .keyDown)

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
    buttonDown.start { _ in handler(.pressed) }
    buttonDragged.start { _ in handler(.dragged) }
    buttonUp.start { _ in handler(.released) }
  }

  func stopObservingPrimaryButton() {
    buttonDown.stop()
    buttonDragged.stop()
    buttonUp.stop()
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
