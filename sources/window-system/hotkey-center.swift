import Carbon.HIToolbox
import os

private let logger = Logger(subsystem: "dev.macousel.app", category: "shortcuts")

private nonisolated func hotKeyHandler(
  _ next: EventHandlerCallRef?, _ event: EventRef?, _ refcon: UnsafeMutableRawPointer?
) -> OSStatus {
  guard let event, let refcon else { return OSStatus(eventNotHandledErr) }
  var hotKeyID = EventHotKeyID()
  let status = GetEventParameter(
    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
    MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
  guard status == noErr else { return status }
  let identifier = hotKeyID.id
  let address = Int(bitPattern: refcon)
  MainActor.assumeIsolated {
    guard let pointer = UnsafeMutableRawPointer(bitPattern: address) else { return }
    Unmanaged<HotkeyCenter>.fromOpaque(pointer).takeUnretainedValue().fire(identifier)
  }
  return noErr
}

public final class HotkeyCenter {
  private static let signature: OSType = 0x4D43_534C

  private var handlerRef: EventHandlerRef?
  private var registrations: [EventHotKeyRef] = []
  private var actions: [UInt32: () -> Void] = [:]
  private var hotkeys: [UInt32: Hotkey] = [:]

  public init() {}

  public func setBindings(_ bindings: [Hotkey: () -> Void]) -> Int {
    unregisterAll()
    guard installHandler() else { return bindings.count }

    var failures = 0
    for (index, entry) in bindings.enumerated() {
      let hotkey = entry.key
      let identifier = UInt32(index + 1)
      var ref: EventHotKeyRef?
      let status = RegisterEventHotKey(
        UInt32(hotkey.keyCode), Self.carbonModifiers(hotkey.modifiers),
        EventHotKeyID(signature: Self.signature, id: identifier),
        GetApplicationEventTarget(), 0, &ref)
      guard status == noErr, let ref else {
        failures += 1
        logger.error(
          """
          RegisterEventHotKey failed: key code \(hotkey.keyCode, privacy: .public), \
          modifiers \(hotkey.modifiers.rawValue, privacy: .public), \
          status \(status, privacy: .public)
          """)
        continue
      }
      registrations.append(ref)
      actions[identifier] = entry.value
      hotkeys[identifier] = hotkey
    }
    return failures
  }

  public func removeAll() {
    unregisterAll()
    if let handlerRef {
      RemoveEventHandler(handlerRef)
      self.handlerRef = nil
    }
  }

  fileprivate func fire(_ identifier: UInt32) {
    if let hotkey = hotkeys[identifier] {
      logger.info(
        """
        hotkey fired: key code \(hotkey.keyCode, privacy: .public), \
        modifiers \(hotkey.modifiers.rawValue, privacy: .public)
        """)
    }
    actions[identifier]?()
  }

  private func unregisterAll() {
    for ref in registrations { UnregisterEventHotKey(ref) }
    registrations = []
    actions = [:]
    hotkeys = [:]
  }

  private func installHandler() -> Bool {
    if handlerRef != nil { return true }
    var spec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let status = InstallEventHandler(
      GetApplicationEventTarget(), hotKeyHandler, 1, &spec,
      Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
    if status != noErr {
      logger.error("InstallEventHandler failed: \(status)")
    }
    return status == noErr
  }

  private static func carbonModifiers(_ modifiers: Hotkey.Modifiers) -> UInt32 {
    var result = 0
    if modifiers.contains(.control) { result |= controlKey }
    if modifiers.contains(.option) { result |= optionKey }
    if modifiers.contains(.shift) { result |= shiftKey }
    if modifiers.contains(.command) { result |= cmdKey }
    return UInt32(result)
  }
}
