import AppKit
import SwiftUI

extension NSWindow {
  static func titleless(title: String, size: NSSize, rootView: some View) -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
    let content = NSHostingView(rootView: rootView)
    content.sizingOptions = []
    window.contentView = content
    window.setContentSize(size)
    window.title = title
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.isReleasedWhenClosed = false
    window.center()
    return window
  }
}
