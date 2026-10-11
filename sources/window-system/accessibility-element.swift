import ApplicationServices

extension AXUIElement {
  nonisolated func attribute<T>(_ name: String) -> T? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success else {
      return nil
    }
    return value as? T
  }

  func elementAttribute(_ name: String) -> AXUIElement? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success,
      let value, CFGetTypeID(value) == AXUIElementGetTypeID()
    else { return nil }
    return (value as! AXUIElement)
  }

  func elementsAttribute(_ name: String) -> [AXUIElement] {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success,
      let array = value as? [CFTypeRef]
    else { return [] }
    return array.compactMap { item in
      CFGetTypeID(item) == AXUIElementGetTypeID() ? (item as! AXUIElement) : nil
    }
  }

  func pointAttribute(_ name: String) -> CGPoint? {
    var point = CGPoint.zero
    guard let value = axValueAttribute(name, type: .cgPoint),
      AXValueGetValue(value, .cgPoint, &point)
    else { return nil }
    return point
  }

  func sizeAttribute(_ name: String) -> CGSize? {
    var size = CGSize.zero
    guard let value = axValueAttribute(name, type: .cgSize),
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

  var windowID: CGWindowID? {
    var id: CGWindowID = 0
    guard _AXUIElementGetWindow(self, &id) == .success, id != 0 else { return nil }
    return id
  }

  private func axValueAttribute(_ name: String, type: AXValueType) -> AXValue? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success,
      let value, CFGetTypeID(value) == AXValueGetTypeID()
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
