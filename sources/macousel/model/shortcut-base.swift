import WindowSystem

enum ShortcutBase: String, Codable, CaseIterable {
  case controlOption
  case option
  case commandOption

  var title: String {
    switch self {
    case .controlOption: "Control-Option"
    case .option: "Option"
    case .commandOption: "Command-Option"
    }
  }

  var symbol: String {
    switch self {
    case .controlOption: "⌃⌥"
    case .option: "⌥"
    case .commandOption: "⌘⌥"
    }
  }

  var warning: String? {
    switch self {
    case .controlOption: nil
    case .option:
      "Option alone blocks the characters it types, such as å and ø, while Macousel runs."
    case .commandOption: "Command-Option overlaps app shortcuts, such as ⌘⌥H to hide other apps."
    }
  }

  /// Maps a modifier set written for Control-Option onto this base.
  func adapting(_ modifiers: Hotkey.Modifiers) -> Hotkey.Modifiers {
    switch self {
    case .controlOption:
      return modifiers
    case .option:
      return modifiers.subtracting(.control)
    case .commandOption:
      var adapted = modifiers.subtracting([.control, .command])
      if modifiers.contains(.control) { adapted.insert(.command) }
      if modifiers.contains(.command) { adapted.insert(.control) }
      return adapted
    }
  }
}
