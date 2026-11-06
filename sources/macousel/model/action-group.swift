nonisolated extension Action {
  enum Group: String, CaseIterable, Sendable {
    case navigate, size, stacks, other

    var title: String {
      switch self {
      case .navigate: "Navigate"
      case .size: "Size"
      case .stacks: "Stacks"
      case .other: "Other"
      }
    }

    var actions: [Action] {
      Action.allCases.filter { $0.group == self }
    }
  }

  var group: Group {
    switch self {
    case .focusLeft, .focusRight, .focusUp, .focusDown, .focusFirst, .focusLast, .focusPrevious,
      .focusColumn,
      .moveLeft, .moveRight, .moveUp, .moveDown, .moveToColumn, .moveToFirst, .moveToLast,
      .sendToNextDisplay, .sendToNextDisplayWithoutFollowing, .focusNextDisplay:
      .navigate
    case .cycleWidth, .toggleFullWidth, .center, .wider, .narrower, .taller, .shorter,
      .equalizeHeights:
      .size
    case .stackLeft, .stackRight, .popOutLeft, .popOutRight, .toggleTabbed, .toggleFloating,
      .switchToFloatingWindows, .bringBackFloatingWindows, .pinWindow, .togglePinnedWindows:
      .stacks
    case .toggleOverview, .sendToScratchpad, .toggleScratchpad, .togglePaused:
      .other
    }
  }
}
