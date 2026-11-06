import AppKit
import SwiftUI

extension NSWindow {
  // Zoom stays dimmed because the content has a fixed size.
  static func guide(title: String, size: NSSize, rootView: some View) -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
    let content = NSHostingView(rootView: rootView)
    content.sizingOptions = []
    window.contentView = content
    window.setContentSize(size)
    window.title = title
    window.isReleasedWhenClosed = false
    window.center()
    return window
  }
}
