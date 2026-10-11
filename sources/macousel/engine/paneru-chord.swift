import WindowSystem

nonisolated enum PaneruChord {
  private static let modifierNames: [(Hotkey.Modifiers, String)] = [
    (.option, "alt"), (.shift, "shift"), (.command, "cmd"), (.control, "ctrl"),
  ]

  static func text(for hotkey: Hotkey) -> String? {
    guard let key = PaneruKeyNames.name(for: hotkey.keyCode) else { return nil }
    let modifiers = modifierNames.filter { hotkey.modifiers.contains($0.0) }.map(\.1)
    return modifiers.isEmpty ? nil : modifiers.joined(separator: " + ") + " - " + key
  }

  static func isAvailable(_ hotkey: Hotkey) -> Bool {
    text(for: hotkey) != nil
  }
}
