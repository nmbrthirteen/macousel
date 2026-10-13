struct EngineConfigSwipe {
  static let sensitivityScale = 0.35
  static let sensitivityRange = 0.1...2.0
  static let disabledScrollModifier = "alt + fn"
  static let scrollModifier = "ctrl + alt"

  let preferences: Preferences

  var sensitivity: Double {
    min(max(Self.sensitivityScale * preferences.swipeSensitivity, Self.sensitivityRange.lowerBound),
      Self.sensitivityRange.upperBound)
  }

  var lines: [String] {
    var gesture = ["[swipe.gesture]"]
    if preferences.swipeGestureEnabled, preferences.swipeStep == .free {
      gesture.append("fingers_count = \(preferences.swipeFingers)")
    }
    gesture += [
      "direction = \(TomlString.quoted(preferences.reversesSwipeDirection ? "Reversed" : "Natural"))",
      "vertical = false",
    ]
    let modifier =
      preferences.scrollGestureEnabled ? Self.scrollModifier : Self.disabledScrollModifier
    return ["[swipe]", "sensitivity = \(TomlNumber.decimal(sensitivity))"] + [""] + gesture + [""]
      + ["[swipe.scroll]", "modifier = \(TomlString.quoted(modifier))"]
  }
}
