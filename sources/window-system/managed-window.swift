import AppKit
import ApplicationServices

public final class ManagedWindow {
  private static let focusQueue = DispatchQueue(
    label: "dev.macousel.focus", qos: .userInteractive)
  private static let focusRequests = FocusRequests()
  private static let windowServerSettleDelay = 0.15

  public let id: CGWindowID
  public let pid: pid_t
  public let bundleIdentifier: String?
  public let appName: String

  let element: AXUIElement
  private let readTimeouts = ReadTimeoutFlag()
  private let applicationElement: AXUIElement

  init(
    id: CGWindowID, element: AXUIElement, applicationElement: AXUIElement,
    app: NSRunningApplication
  ) {
    self.id = id
    self.element = element
    self.applicationElement = applicationElement
    self.pid = app.processIdentifier
    self.bundleIdentifier = app.bundleIdentifier
    self.appName = app.localizedName ?? ""
    AXUIElementSetMessagingTimeout(element, WindowTracker.messagingTimeout)
  }

  public func takeReadTimeout() -> Bool {
    readTimeouts.take()
  }

  public var title: String {
    element.attribute(kAXTitleAttribute, noting: readTimeouts) ?? ""
  }

  public var frame: CGRect? {
    guard let origin = element.pointAttribute(kAXPositionAttribute, noting: readTimeouts),
      let size = element.sizeAttribute(kAXSizeAttribute, noting: readTimeouts)
    else { return nil }
    return CGRect(origin: origin, size: size)
  }

  public func setFrame(_ frame: CGRect) {
    let enhanced: Bool = applicationElement.attribute("AXEnhancedUserInterface") ?? false
    if enhanced { applicationElement.set(bool: false, for: "AXEnhancedUserInterface") }
    defer {
      if enhanced { applicationElement.set(bool: true, for: "AXEnhancedUserInterface") }
    }

    element.set(size: frame.size, for: kAXSizeAttribute)
    element.set(point: frame.origin, for: kAXPositionAttribute)
    element.set(size: frame.size, for: kAXSizeAttribute)
  }

  public func setPosition(_ origin: CGPoint) {
    element.set(point: origin, for: kAXPositionAttribute)
  }

  public var isMinimized: Bool {
    element.attribute(kAXMinimizedAttribute, noting: readTimeouts) ?? false
  }

  public var isFullScreen: Bool {
    element.attribute("AXFullScreen", noting: readTimeouts) ?? false
  }

  public var isTileable: Bool {
    guard element.attribute(kAXRoleAttribute, noting: readTimeouts) == kAXWindowRole,
      element.attribute(kAXSubroleAttribute, noting: readTimeouts) == kAXStandardWindowSubrole
    else { return false }
    var settable: DarwinBoolean = false
    guard AXUIElementIsAttributeSettable(element, kAXSizeAttribute as CFString, &settable)
      == .success
    else { return false }
    return settable.boolValue
  }

  public func focus() {
    let target = ThreadSafeAXElement(element: element)
    let pid = pid
    let id = id
    let requests = Self.focusRequests
    let settleDelay = Self.windowServerSettleDelay
    let request = requests.begin()
    Self.focusQueue.async {
      guard requests.isLatest(request) else { return }
      let usedWindowServer =
        request.usesWindowServer && WindowServerFocus.shared.bringToFront(id, of: pid)
      AXUIElementPerformAction(target.element, kAXRaiseAction as CFString)
      target.element.set(bool: true, for: kAXMainAttribute)
      DispatchQueue.main.asyncAfter(
        deadline: .now() + (usedWindowServer ? settleDelay : 0)
      ) {
        guard requests.isLatest(request) else { return }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier != pid else {
          if usedWindowServer { requests.recordHit() }
          return
        }
        if usedWindowServer { requests.recordMiss() }
        NSRunningApplication(processIdentifier: pid)?.activate()
      }
    }
  }

  public func close() {
    guard let button = element.elementAttribute(kAXCloseButtonAttribute) else { return }
    AXUIElementPerformAction(button, kAXPressAction as CFString)
  }
}
