import Carbon.HIToolbox
import WindowSystem

extension Hotkey {
  fileprivate init(_ key: Int, _ modifiers: Modifiers) {
    self.init(keyCode: UInt16(key), modifiers: modifiers)
  }
}

extension Action {
  static let defaultShortcuts: [Action: [Hotkey]] = {
    let base: Hotkey.Modifiers = [.control, .option]
    let shifted: Hotkey.Modifiers = [.control, .option, .shift]
    let commanded: Hotkey.Modifiers = [.control, .option, .command]

    return [
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
    ]
  }()
}
