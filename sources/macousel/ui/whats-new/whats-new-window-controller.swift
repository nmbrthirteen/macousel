import AppKit
import SwiftUI

final class WhatsNewWindowController {
  private var window: NSWindow?

  func show(_ notes: ReleaseNotes) {
    let size = NSSize(width: WhatsNewMetrics.width, height: WhatsNewMetrics.height)
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
    let content = NSHostingView(rootView: WhatsNewView(notes: notes) { [weak self] in self?.close() })
    content.sizingOptions = []
    window.contentView = content
    window.title = "What's new in Macousel"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.isReleasedWhenClosed = false
    window.center()
    self.window = window
    NSApp.activate()
    window.makeKeyAndOrderFront(nil)
  }

  private func close() {
    window?.close()
    window = nil
  }
}
