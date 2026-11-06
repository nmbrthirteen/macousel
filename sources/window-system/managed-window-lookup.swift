import AppKit
import ApplicationServices

extension ManagedWindow {
  // For callers without a WindowTracker: the window server names the owner, and only that
  // app's windows are asked for their IDs.
  public static func lookUp(_ id: CGWindowID) -> ManagedWindow? {
    guard
      let list = CGWindowListCopyWindowInfo([.optionIncludingWindow], id) as? [[String: Any]],
      let pid = list.first?[kCGWindowOwnerPID as String] as? pid_t,
      let app = NSRunningApplication(processIdentifier: pid)
    else { return nil }
    let application = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(application, WindowTracker.messagingTimeout)
    guard
      let element = application.elementsAttribute(kAXWindowsAttribute).first(where: {
        $0.windowID == id
      })
    else { return nil }
    return ManagedWindow(id: id, element: element, applicationElement: application, app: app)
  }
}
