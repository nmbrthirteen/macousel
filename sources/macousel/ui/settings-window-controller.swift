import AppKit
import SwiftUI

// The Settings window is a SwiftUI scene, because only a scene gets the system title, sidebar
// toggle, and corner radius. AppKit code can only open it through an action captured from a view.
final class SettingsWindowController {
  static let windowID = "settings"
  static let openerWindowID = "opener"

  private let onVisibilityChange: (Bool) -> Void
  private var openWindow: OpenWindowAction?
  private var opensWhenReady = false

  init(onVisibilityChange: @escaping (Bool) -> Void) {
    self.onVisibilityChange = onVisibilityChange
  }

  func show(section: SettingsSection? = nil) {
    if let section {
      UserDefaults.standard.set(section.rawValue, forKey: SettingsSection.storageKey)
    }
    guard let openWindow else {
      opensWhenReady = true
      return
    }
    onVisibilityChange(true)
    NSApp.activate()
    openWindow(id: Self.windowID)
  }

  func capture(_ action: OpenWindowAction) {
    openWindow = action
    guard opensWhenReady else { return }
    opensWhenReady = false
    show()
  }

  func windowDidAppear() {
    onVisibilityChange(true)
  }

  func windowDidClose() {
    onVisibilityChange(false)
    MemoryRelief.returnFreedPages()
  }
}
