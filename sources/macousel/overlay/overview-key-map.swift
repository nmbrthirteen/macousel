import Carbon.HIToolbox
import StripCore

enum OverviewKeyMap {
  private static let places = [
    kVK_ANSI_1: 1, kVK_ANSI_2: 2, kVK_ANSI_3: 3, kVK_ANSI_4: 4, kVK_ANSI_5: 5,
    kVK_ANSI_6: 6, kVK_ANSI_7: 7, kVK_ANSI_8: 8, kVK_ANSI_9: 9,
  ]

  static func key(forKeyCode keyCode: UInt16, shifted: Bool = false) -> OverviewKey? {
    let code = Int(keyCode)
    if let place = places[code] { return shifted ? .moveWindowToPlace(place) : .jump(place) }
    if let direction = direction(forKeyCode: code) {
      return shifted ? .moveWindow(direction) : .move(direction)
    }
    switch code {
    case kVK_ANSI_Equal, kVK_ANSI_KeypadPlus: return .widen
    case kVK_ANSI_Minus, kVK_ANSI_KeypadMinus: return .narrow
    case kVK_Return, kVK_ANSI_KeypadEnter: return .confirm
    case kVK_Escape: return .dismiss
    default: return nil
    }
  }

  private static func direction(forKeyCode code: Int) -> Direction? {
    switch code {
    case kVK_LeftArrow, kVK_ANSI_H: .left
    case kVK_RightArrow, kVK_ANSI_L: .right
    case kVK_UpArrow, kVK_ANSI_K: .up
    case kVK_DownArrow, kVK_ANSI_J: .down
    default: nil
    }
  }
}
