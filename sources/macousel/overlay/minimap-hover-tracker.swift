import AppKit

final class MinimapHoverTracker: NSResponder {
  var onEnter: () -> Void = {}
  var onMove: (CGPoint) -> Void = { _ in }
  var onExit: () -> Void = {}
  private weak var view: NSView?

  func attach(to view: NSView) {
    self.view = view
    view.addTrackingArea(
      NSTrackingArea(
        rect: .zero,
        options: [
          .mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect,
          .enabledDuringMouseDrag,
        ],
        owner: self))
  }

  override func mouseEntered(with event: NSEvent) {
    onEnter()
  }

  // SwiftUI lays the minimap out from the top left, while the material view is not flipped.
  override func mouseMoved(with event: NSEvent) {
    guard let view else { return }
    let point = view.convert(event.locationInWindow, from: nil)
    onMove(CGPoint(x: point.x, y: view.isFlipped ? point.y : view.bounds.height - point.y))
  }

  override func mouseExited(with event: NSEvent) {
    onExit()
  }
}
