import Carbon.HIToolbox

nonisolated enum PaneruKeyNames {
  static func name(for keyCode: UInt16) -> String? {
    table[Int(keyCode)]
  }

  private static let table: [Int: String] = [
    kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d", kVK_ANSI_E: "e",
    kVK_ANSI_F: "f", kVK_ANSI_G: "g", kVK_ANSI_H: "h", kVK_ANSI_I: "i", kVK_ANSI_J: "j",
    kVK_ANSI_K: "k", kVK_ANSI_L: "l", kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o",
    kVK_ANSI_P: "p", kVK_ANSI_Q: "q", kVK_ANSI_R: "r", kVK_ANSI_S: "s", kVK_ANSI_T: "t",
    kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x", kVK_ANSI_Y: "y",
    kVK_ANSI_Z: "z",
    kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4",
    kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8", kVK_ANSI_9: "9",
    kVK_ANSI_Equal: "equal", kVK_ANSI_Minus: "minus", kVK_ANSI_LeftBracket: "leftbracket",
    kVK_ANSI_RightBracket: "rightbracket", kVK_ANSI_Quote: "quote",
    kVK_ANSI_Semicolon: "semicolon", kVK_ANSI_Backslash: "backslash", kVK_ANSI_Comma: "comma",
    kVK_ANSI_Slash: "slash", kVK_ANSI_Period: "period", kVK_ANSI_Grave: "grave",
    kVK_Return: "return", kVK_Tab: "tab", kVK_Space: "space", kVK_Delete: "delete",
    kVK_Escape: "escape",
    kVK_F1: "f1", kVK_F2: "f2", kVK_F3: "f3", kVK_F4: "f4", kVK_F5: "f5", kVK_F6: "f6",
    kVK_F7: "f7", kVK_F8: "f8", kVK_F9: "f9", kVK_F10: "f10", kVK_F11: "f11", kVK_F12: "f12",
    kVK_F13: "f13", kVK_F14: "f14", kVK_F15: "f15", kVK_F16: "f16", kVK_F17: "f17",
    kVK_F18: "f18", kVK_F19: "f19", kVK_F20: "f20",
    kVK_Home: "home", kVK_End: "end", kVK_PageUp: "pageup", kVK_PageDown: "pagedown",
    kVK_LeftArrow: "leftarrow", kVK_RightArrow: "rightarrow", kVK_UpArrow: "uparrow",
    kVK_DownArrow: "downarrow",
  ]
}
