import ApplicationServices

extension WindowFactsReader {
  public func read(
    _ windows: [ManagedWindow], focusing focusedPID: pid_t?,
    completion: @escaping @MainActor (WindowProbeResult) -> Void
  ) {
    let items = windows.map { window in
      let target = ThreadSafeAXElement(element: window.element)
      return WindowReadItem(id: window.id, pid: window.pid, read: { target.element.windowFacts() })
    }
    let timeout = WindowTracker.messagingTimeout
    let focus = focusedPID.map { pid in
      FocusReadItem(
        pid: pid,
        read: {
          let application = AXUIElementCreateApplication(pid)
          AXUIElementSetMessagingTimeout(application, timeout)
          return application.elementAttribute(kAXFocusedWindowAttribute)?.windowID
        })
    }
    read(items, focus: focus, completion: completion)
  }
}
