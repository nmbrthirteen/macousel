import Carbon.HIToolbox
import StripCore

enum OverviewKeyMap {
  private static let places = [
    kVK_ANSI_1: 1, kVK_ANSI_2: 2, kVK_ANSI_3: 3, kVK_ANSI_4: 4, kVK_ANSI_5: 5,
    kVK_ANSI_6: 6, kVK_ANSI_7: 7, kVK_ANSI_8: 8, kVK_ANSI_9: 9,
  ]

  static func key(forKeyCode keyCode: UInt16) -> OverviewKey? {
    let code = Int(keyCode)
    if let place = places[code] { return .jump(place) }
    switch code {
    case kVK_LeftArrow, kVK_ANSI_H: return .move(.left)
    case kVK_RightArrow, kVK_ANSI_L: return .move(.right)
    case kVK_UpArrow, kVK_ANSI_K: return .move(.up)
    case kVK_DownArrow, kVK_ANSI_J: return .move(.down)
    case kVK_Return, kVK_ANSI_KeypadEnter: return .confirm
    case kVK_Escape: return .dismiss
    default: return nil
    }
  }
}
