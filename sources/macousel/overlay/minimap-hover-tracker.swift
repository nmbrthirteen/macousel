import AppKit

final class MinimapHoverTracker: NSResponder {
  var onEnter: () -> Void = {}
  var onExit: () -> Void = {}

  func attach(to view: NSView) {
    view.addTrackingArea(
      NSTrackingArea(
        rect: .zero,
        options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect, .enabledDuringMouseDrag],
        owner: self))
  }

  override func mouseEntered(with event: NSEvent) {
    onEnter()
  }

  override func mouseExited(with event: NSEvent) {
    onExit()
  }
}
