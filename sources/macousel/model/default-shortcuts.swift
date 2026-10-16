import Carbon.HIToolbox
import WindowSystem

extension Hotkey {
  fileprivate init(_ key: Int, _ modifiers: Modifiers) {
    self.init(keyCode: UInt16(key), modifiers: modifiers)
  }
}

extension Action {
  static let defaultShortcuts = defaultShortcuts(base: .controlOption)

  static func defaultShortcuts(base shortcutBase: ShortcutBase) -> [Action: [Hotkey]] {
    let base: Hotkey.Modifiers = [.control, .option]
    let shifted: Hotkey.Modifiers = [.control, .option, .shift]
    let commanded: Hotkey.Modifiers = [.control, .option, .command]
    let everyModifier: Hotkey.Modifiers = [.control, .option, .command, .shift]
    let placeKeys = [
      kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
      kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
    ]

    var shortcuts: [Action: [Hotkey]] = [
      .focusLeft: [Hotkey(kVK_ANSI_H, base), Hotkey(kVK_LeftArrow, base)],
      .focusDown: [Hotkey(kVK_ANSI_J, base), Hotkey(kVK_DownArrow, base)],
      .focusUp: [Hotkey(kVK_ANSI_K, base), Hotkey(kVK_UpArrow, base)],
      .focusRight: [Hotkey(kVK_ANSI_L, base), Hotkey(kVK_RightArrow, base)],
      .focusFirst: [Hotkey(kVK_LeftArrow, commanded)],
      .focusLast: [Hotkey(kVK_RightArrow, commanded)],
      .moveLeft: [Hotkey(kVK_ANSI_H, shifted), Hotkey(kVK_LeftArrow, shifted)],
      .moveDown: [Hotkey(kVK_ANSI_J, shifted), Hotkey(kVK_DownArrow, shifted)],
      .moveUp: [Hotkey(kVK_ANSI_K, shifted), Hotkey(kVK_UpArrow, shifted)],
      .moveRight: [Hotkey(kVK_ANSI_L, shifted), Hotkey(kVK_RightArrow, shifted)],
      .moveToFirst: [Hotkey(kVK_LeftArrow, everyModifier)],
      .moveToLast: [Hotkey(kVK_RightArrow, everyModifier)],
      .sendToNextDisplay: [Hotkey(kVK_ANSI_N, base)],
      .togglePaused: [Hotkey(kVK_ANSI_Q, base)],
      .cycleWidth: [Hotkey(kVK_ANSI_R, base)],
      .toggleFullWidth: [Hotkey(kVK_ANSI_F, base)],
      .center: [Hotkey(kVK_ANSI_C, base)],
      .wider: [Hotkey(kVK_ANSI_Equal, base)],
      .narrower: [Hotkey(kVK_ANSI_Minus, base)],
      .taller: [Hotkey(kVK_ANSI_Equal, shifted)],
      .shorter: [Hotkey(kVK_ANSI_Minus, shifted)],
      .equalizeHeights: [Hotkey(kVK_ANSI_0, base)],
      .stackLeft: [Hotkey(kVK_ANSI_RightBracket, base)],
      .stackRight: [Hotkey(kVK_ANSI_LeftBracket, base)],
      .popOutRight: [Hotkey(kVK_ANSI_RightBracket, shifted)],
      .popOutLeft: [Hotkey(kVK_ANSI_LeftBracket, shifted)],
      .toggleTabbed: [Hotkey(kVK_ANSI_T, shifted)],
      .toggleFloating: [Hotkey(kVK_ANSI_T, base)],
      .toggleOverview: [Hotkey(kVK_ANSI_O, base)],
      .sendToScratchpad: [Hotkey(kVK_ANSI_S, shifted)],
      .toggleScratchpad: [Hotkey(kVK_ANSI_S, base)],
    ]
    for (place, key) in zip(Action.places, placeKeys) {
      shortcuts[.focusColumn(place)] = [Hotkey(key, base)]
      shortcuts[.moveToColumn(place)] = [Hotkey(key, shifted)]
    }
    return shortcuts.mapValues { hotkeys in
      hotkeys.map { Hotkey(keyCode: $0.keyCode, modifiers: shortcutBase.adapting($0.modifiers)) }
    }
  }
}
