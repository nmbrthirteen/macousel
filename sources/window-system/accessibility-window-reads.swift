import ApplicationServices
import CoreGraphics

nonisolated extension AXUIElement {
  func windowTitle(noting timeouts: ReadTimeoutFlag? = nil) -> String {
    attribute(kAXTitleAttribute, noting: timeouts) ?? ""
  }

  func windowFrame(noting timeouts: ReadTimeoutFlag? = nil) -> CGRect? {
    guard let origin = pointAttribute(kAXPositionAttribute, noting: timeouts),
      let size = sizeAttribute(kAXSizeAttribute, noting: timeouts)
    else { return nil }
    return CGRect(origin: origin, size: size)
  }

  func isFullScreenWindow(noting timeouts: ReadTimeoutFlag? = nil) -> Bool {
    attribute("AXFullScreen", noting: timeouts) ?? false
  }

  func isTileableWindow(noting timeouts: ReadTimeoutFlag? = nil) -> Bool {
    guard attribute(kAXRoleAttribute, noting: timeouts) == kAXWindowRole,
      attribute(kAXSubroleAttribute, noting: timeouts) == kAXStandardWindowSubrole
    else { return false }
    var settable: DarwinBoolean = false
    guard AXUIElementIsAttributeSettable(self, kAXSizeAttribute as CFString, &settable) == .success
    else { return false }
    return settable.boolValue
  }

  func windowFacts() -> WindowFacts {
    let timeouts = ReadTimeoutFlag()
    let isTileable = isTileableWindow(noting: timeouts)
    let isFullScreen = isFullScreenWindow(noting: timeouts)
    let frame = windowFrame(noting: timeouts)
    let title = windowTitle(noting: timeouts)
    return WindowFacts(
      isTileable: isTileable, isFullScreen: isFullScreen, frame: frame, title: title,
      timedOut: timeouts.take())
  }
}
