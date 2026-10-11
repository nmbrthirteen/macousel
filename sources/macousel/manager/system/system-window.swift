import CoreGraphics
import WindowSystem

final class SystemWindow: WindowHandle {
  private let window: ManagedWindow

  init(_ window: ManagedWindow) {
    self.window = window
  }

  var id: CGWindowID { window.id }
  var pid: pid_t { window.pid }
  var bundleIdentifier: String? { window.bundleIdentifier }
  var appName: String { window.appName }
  var title: String { window.title }
  var frame: CGRect? { window.frame }

  func setFrame(_ frame: CGRect) {
    window.setFrame(frame)
  }

  func focus(raising: Bool) {
    window.focus(raising: raising)
  }

  func raise() {
    window.raise()
  }
}
