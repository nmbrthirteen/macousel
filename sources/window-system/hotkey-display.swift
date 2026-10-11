import AppKit
import Carbon.HIToolbox

extension Hotkey {
  public var displayString: String {
    var result = ""
    if modifiers.contains(.control) { result += "⌃" }
    if modifiers.contains(.option) { result += "⌥" }
    if modifiers.contains(.shift) { result += "⇧" }
    if modifiers.contains(.command) { result += "⌘" }
    return result + (Self.namedKeys[Int(keyCode)] ?? Self.layoutGlyph(for: keyCode))
  }

  public init?(event: NSEvent) {
    guard event.type == .keyDown else { return nil }
    var modifiers: Modifiers = []
    let flags = event.modifierFlags
    if flags.contains(.control) { modifiers.insert(.control) }
    if flags.contains(.option) { modifiers.insert(.option) }
    if flags.contains(.shift) { modifiers.insert(.shift) }
    if flags.contains(.command) { modifiers.insert(.command) }
    guard !modifiers.isDisjoint(with: [.control, .option, .command]) else { return nil }
    self.init(keyCode: event.keyCode, modifiers: modifiers)
  }

  private static let namedKeys: [Int: String] = [
    kVK_Return: "Return", kVK_ANSI_KeypadEnter: "Enter", kVK_Space: "Space", kVK_Tab: "Tab",
    kVK_Escape: "Escape", kVK_Delete: "Delete", kVK_ForwardDelete: "Forward Delete",
    kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
    kVK_Home: "Home", kVK_End: "End", kVK_PageUp: "Page Up", kVK_PageDown: "Page Down",
    kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
    kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
  ]

  private static func layoutGlyph(for keyCode: UInt16) -> String {
    guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
      let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else { return "Key \(keyCode)" }
    let layoutData = Unmanaged<CFData>.fromOpaque(property).takeUnretainedValue()

    let keyboardType = UInt32(CGEventSource(stateID: .hidSystemState)?.keyboardType ?? 0)
    var deadKeyState: UInt32 = 0
    var length = 0
    var characters = [UniChar](repeating: 0, count: 4)
    let status = CFDataGetBytePtr(layoutData).withMemoryRebound(
      to: UCKeyboardLayout.self, capacity: 1
    ) { layout in
      UCKeyTranslate(
        layout, keyCode, UInt16(kUCKeyActionDisplay), 0,
        keyboardType, OptionBits(kUCKeyTranslateNoDeadKeysBit),
        &deadKeyState, characters.count, &length, &characters)
    }
    guard status == noErr, length > 0 else { return "Key \(keyCode)" }
    return String(utf16CodeUnits: characters, count: length).uppercased()
  }
}
