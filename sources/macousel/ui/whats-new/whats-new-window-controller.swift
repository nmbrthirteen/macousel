import AppKit
import SwiftUI

final class WhatsNewWindowController {
  private var window: NSWindow?
  private var closeObserver: (any NSObjectProtocol)?

  func show(_ notes: ReleaseNotes) {
    let window = makeWindow(notes)
    self.window = window
    NSApp.activate()
    window.makeKeyAndOrderFront(nil)
  }

  // A closed window that is not released keeps its SwiftUI views alive.
  private func windowWillClose() {
    if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
    closeObserver = nil
    window?.contentView = nil
    window = nil
  }

  private func makeWindow(_ notes: ReleaseNotes) -> NSWindow {
    let window = NSWindow.guide(
      title: "What's new in Macousel",
      size: NSSize(width: WhatsNewMetrics.width, height: WhatsNewMetrics.height),
      rootView: WhatsNewView(notes: notes) { [weak self] in self?.window?.close() })
    closeObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification, object: window, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.windowWillClose() }
    }
    return window
  }
}
