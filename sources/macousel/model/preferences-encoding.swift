extension Preferences {
  enum CodingKeys: String, CodingKey {
    case engine, layout, shortcuts, animationSpeed, showsFocusBorder, focusBorderWidth
    case dimsInactiveWindows, dimAmount, showsMinimap, menuBarIndicator, restoresSession
    case scrollGestureEnabled, swipeGestureEnabled, swipeFingers, swipeSensitivity, reversesSwipeDirection
    case displayFollowsPointer, focusFollowsMouse, mouseFollowsFocus, keepsFloatingWindowsOnTop
    case appRules, appShortcuts, disabledDisplays, hasCompletedOnboarding, checksForUpdates
  }

  func encode(to encoder: Encoder) throws {
    try encode(to: encoder, includingOnboarding: true, sortingUnorderedValues: false)
  }

  func encode(
    to encoder: Encoder, includingOnboarding: Bool, sortingUnorderedValues: Bool
  ) throws {
    var values = encoder.container(keyedBy: CodingKeys.self)
    try values.encode(engine, forKey: .engine)
    try values.encode(layout, forKey: .layout)
    if sortingUnorderedValues {
      try values.encode(SortedShortcuts(shortcuts: shortcuts), forKey: .shortcuts)
    } else {
      try values.encode(shortcuts, forKey: .shortcuts)
    }
    try values.encode(animationSpeed, forKey: .animationSpeed)
    try values.encode(showsFocusBorder, forKey: .showsFocusBorder)
    try values.encode(focusBorderWidth, forKey: .focusBorderWidth)
    try values.encode(dimsInactiveWindows, forKey: .dimsInactiveWindows)
    try values.encode(dimAmount, forKey: .dimAmount)
    try values.encode(showsMinimap, forKey: .showsMinimap)
    try values.encode(menuBarIndicator, forKey: .menuBarIndicator)
    try values.encode(restoresSession, forKey: .restoresSession)
    try values.encode(scrollGestureEnabled, forKey: .scrollGestureEnabled)
    try values.encode(swipeGestureEnabled, forKey: .swipeGestureEnabled)
    try values.encode(swipeFingers, forKey: .swipeFingers)
    try values.encode(swipeSensitivity, forKey: .swipeSensitivity)
    try values.encode(reversesSwipeDirection, forKey: .reversesSwipeDirection)
    try values.encode(displayFollowsPointer, forKey: .displayFollowsPointer)
    try values.encode(focusFollowsMouse, forKey: .focusFollowsMouse)
    try values.encode(mouseFollowsFocus, forKey: .mouseFollowsFocus)
    try values.encode(keepsFloatingWindowsOnTop, forKey: .keepsFloatingWindowsOnTop)
    try values.encode(appRules, forKey: .appRules)
    try values.encode(appShortcuts, forKey: .appShortcuts)
    if sortingUnorderedValues {
      try values.encode(disabledDisplays.sorted(), forKey: .disabledDisplays)
    } else {
      try values.encode(disabledDisplays, forKey: .disabledDisplays)
    }
    try values.encode(checksForUpdates, forKey: .checksForUpdates)
    if includingOnboarding {
      try values.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    }
  }
}
