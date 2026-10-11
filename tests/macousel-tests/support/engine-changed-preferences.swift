import Carbon.HIToolbox
import StripCore
import WindowSystem

@testable import Macousel

extension Preferences {
  @MainActor
  static func everySettingChangedForTheEngine() -> Preferences {
    var preferences = Preferences()
    preferences.layout = LayoutConfig(
      innerGap: 13, outerGap: 22, presetWidths: [0.3, 0.45, 0.6, 1.0], defaultWidth: 0.4,
      centerMode: .always)
    preferences.animationSpeed = .relaxed
    preferences.showsFocusBorder = false
    preferences.focusBorderWidth = 5
    preferences.dimsInactiveWindows = true
    preferences.dimAmount = 0.35
    preferences.restoresSession = false
    preferences.scrollGestureEnabled = false
    preferences.swipeGestureEnabled = true
    preferences.swipeFingers = 3
    preferences.swipeSensitivity = 2.0
    preferences.reversesSwipeDirection = true
    preferences.focusFollowsMouse = true
    preferences.mouseFollowsFocus = true
    preferences.appRules = [
      AppRule(bundleIdentifier: "com.apple.Calculator", behavior: .float),
      AppRule(bundleIdentifier: "com.example.Editor", behavior: .width(0.6)),
      AppRule(bundleIdentifier: "com.example.Chat", behavior: .slot(3)),
      AppRule(bundleIdentifier: "com.Example-App.v2", behavior: .float),
      AppRule(bundleIdentifier: "com.example_app.v2", behavior: .float),
    ]
    preferences.shortcuts[.focusLeft] = [
      Hotkey(keyCode: UInt16(kVK_ANSI_J), modifiers: [.control, .command])
    ]
    preferences.shortcuts[.focusRight] = [
      Hotkey(keyCode: UInt16(kVK_ANSI_KeypadEnter), modifiers: [.control]),
      Hotkey(keyCode: UInt16(kVK_F5), modifiers: [.option]),
    ]
    preferences.shortcuts[.toggleFloating] = []
    return preferences
  }
}
