import AppKit
import ApplicationServices

nonisolated enum FocusedWindowReader {
  static func current() -> (window: CGWindowID, pid: pid_t)? {
    guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
      let window = AXUIElementCreateApplication(pid).elementAttribute(kAXFocusedWindowAttribute)?
        .windowID
    else { return nil }
    return (window, pid)
  }
}
