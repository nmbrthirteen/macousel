import AppKit
import SwiftUI

final class WhatsNewWindowController {
  private var window: NSWindow?

  func show(_ notes: ReleaseNotes) {
    let window = NSWindow.titleless(
      title: "What's new in Macousel",
      size: NSSize(width: WhatsNewMetrics.width, height: WhatsNewMetrics.height),
      rootView: WhatsNewView(notes: notes) { [weak self] in self?.close() })
    self.window = window
    NSApp.activate()
    window.makeKeyAndOrderFront(nil)
  }

  private func close() {
    window?.close()
    window = nil
  }
}
