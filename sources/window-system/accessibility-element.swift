import ApplicationServices

extension AXUIElement {
  nonisolated func attribute<T>(_ name: String, noting timeouts: ReadTimeoutFlag? = nil) -> T? {
    copyValue(name, noting: timeouts) as? T
  }

  nonisolated func elementAttribute(_ name: String) -> AXUIElement? {
    guard let value = copyValue(name, noting: nil), CFGetTypeID(value) == AXUIElementGetTypeID()
    else { return nil }
    return (value as! AXUIElement)
  }

  func elementsAttribute(_ name: String) -> [AXUIElement] {
    guard let array = copyValue(name, noting: nil) as? [CFTypeRef] else { return [] }
    return array.compactMap { item in
      CFGetTypeID(item) == AXUIElementGetTypeID() ? (item as! AXUIElement) : nil
    }
  }

  nonisolated func pointAttribute(_ name: String, noting timeouts: ReadTimeoutFlag? = nil)
    -> CGPoint?
  {
    var point = CGPoint.zero
    guard let value = axValueAttribute(name, type: .cgPoint, noting: timeouts),
      AXValueGetValue(value, .cgPoint, &point)
    else { return nil }
    return point
  }

  nonisolated func sizeAttribute(_ name: String, noting timeouts: ReadTimeoutFlag? = nil)
    -> CGSize?
  {
    var size = CGSize.zero
    guard let value = axValueAttribute(name, type: .cgSize, noting: timeouts),
      AXValueGetValue(value, .cgSize, &size)
    else { return nil }
    return size
  }

  @discardableResult
  nonisolated func set(point: CGPoint, for name: String) -> Bool {
    var point = point
    guard let value = AXValueCreate(.cgPoint, &point) else { return false }
    return AXUIElementSetAttributeValue(self, name as CFString, value) == .success
  }

  @discardableResult
  nonisolated func set(size: CGSize, for name: String) -> Bool {
    var size = size
    guard let value = AXValueCreate(.cgSize, &size) else { return false }
    return AXUIElementSetAttributeValue(self, name as CFString, value) == .success
  }

  @discardableResult
  nonisolated func set(bool: Bool, for name: String) -> Bool {
    let value: CFBoolean = bool ? kCFBooleanTrue : kCFBooleanFalse
    return AXUIElementSetAttributeValue(self, name as CFString, value) == .success
  }

  nonisolated var windowID: CGWindowID? {
    var id: CGWindowID = 0
    guard _AXUIElementGetWindow(self, &id) == .success, id != 0 else { return nil }
    return id
  }

  private nonisolated func copyValue(_ name: String, noting timeouts: ReadTimeoutFlag?)
    -> CFTypeRef?
  {
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(self, name as CFString, &value)
    if error == .cannotComplete { timeouts?.note() }
    return error == .success ? value : nil
  }

  private nonisolated func axValueAttribute(
    _ name: String, type: AXValueType, noting timeouts: ReadTimeoutFlag?
  ) -> AXValue? {
    guard let value = copyValue(name, noting: timeouts), CFGetTypeID(value) == AXValueGetTypeID()
    else { return nil }
    let axValue = value as! AXValue
    return AXValueGetType(axValue) == type ? axValue : nil
  }
}

struct ElementKey: Hashable {
  let element: AXUIElement

  static func == (lhs: ElementKey, rhs: ElementKey) -> Bool {
    CFEqual(lhs.element, rhs.element)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(CFHash(element))
  }
}
