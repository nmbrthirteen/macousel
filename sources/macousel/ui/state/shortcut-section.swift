enum ShortcutSection: CaseIterable {
  case focus, jumpToColumn, move, moveToColumn, size, stacks, overviewAndTiling

  init(_ action: Action) {
    switch action {
    case .focusLeft, .focusRight, .focusUp, .focusDown, .focusFirst, .focusLast, .focusPrevious,
      .focusNextDisplay:
      self = .focus
    case .focusColumn: self = .jumpToColumn
    case .moveLeft, .moveRight, .moveUp, .moveDown, .moveToFirst, .moveToLast,
      .sendToNextDisplay, .sendToNextDisplayWithoutFollowing:
      self = .move
    case .moveToColumn: self = .moveToColumn
    case .cycleWidth, .toggleFullWidth, .center, .wider, .narrower, .taller, .shorter,
      .equalizeHeights:
      self = .size
    case .stackLeft, .stackRight, .popOutLeft, .popOutRight, .toggleTabbed, .toggleFloating,
      .switchToFloatingWindows, .bringBackFloatingWindows, .pinWindow, .togglePinnedWindows:
      self = .stacks
    case .toggleOverview, .sendToScratchpad, .toggleScratchpad, .togglePaused:
      self = .overviewAndTiling
    }
  }

  var title: String {
    switch self {
    case .focus: "Focus"
    case .jumpToColumn: "Jump to a column"
    case .move: "Move"
    case .moveToColumn: "Move to a column"
    case .size: "Size"
    case .stacks: "Stacks"
    case .overviewAndTiling: "Overview and tiling"
    }
  }

  var actions: [Action] {
    Action.allCases.filter { ShortcutSection($0) == self }
  }
}
