nonisolated extension Action {
  enum Group: String, CaseIterable, Sendable {
    case navigate, size, stacks

    var title: String {
      switch self {
      case .navigate: "Navigate"
      case .size: "Size"
      case .stacks: "Stacks"
      }
    }
  }

  var group: Group {
    switch self {
    case .focusLeft, .focusRight, .focusUp, .focusDown, .focusFirst, .focusLast, .focusColumn,
      .moveLeft, .moveRight, .moveUp, .moveDown, .moveToColumn, .moveToFirst, .moveToLast,
      .sendToNextDisplay, .togglePaused:
      .navigate
    case .cycleWidth, .toggleFullWidth, .center, .wider, .narrower, .taller, .shorter,
      .equalizeHeights:
      .size
    case .stackLeft, .stackRight, .popOutLeft, .popOutRight, .toggleTabbed, .toggleFloating:
      .stacks
    }
  }
}
