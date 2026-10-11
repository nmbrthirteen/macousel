enum Action: String, CaseIterable, Codable, Sendable {
  case focusLeft, focusRight, focusUp, focusDown
  case focusFirst, focusLast
  case moveLeft, moveRight, moveUp, moveDown
  case sendToNextDisplay
  case togglePaused

  case cycleWidth, toggleFullWidth, center
  case wider, narrower
  case taller, shorter
  case equalizeHeights

  case stackLeft, stackRight
  case popOutLeft, popOutRight
  case toggleTabbed
  case toggleFloating

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
    case .focusLeft, .focusRight, .focusUp, .focusDown, .focusFirst, .focusLast,
      .moveLeft, .moveRight, .moveUp, .moveDown, .sendToNextDisplay, .togglePaused:
      .navigate
    case .cycleWidth, .toggleFullWidth, .center, .wider, .narrower, .taller, .shorter,
      .equalizeHeights:
      .size
    case .stackLeft, .stackRight, .popOutLeft, .popOutRight, .toggleTabbed, .toggleFloating:
      .stacks
    }
  }

  var title: String {
    switch self {
    case .focusLeft: "Focus left"
    case .focusRight: "Focus right"
    case .focusUp: "Focus up"
    case .focusDown: "Focus down"
    case .focusFirst: "Focus first window"
    case .focusLast: "Focus last window"
    case .moveLeft: "Move left"
    case .moveRight: "Move right"
    case .moveUp: "Move up"
    case .moveDown: "Move down"
    case .sendToNextDisplay: "Send to next display"
    case .togglePaused: "Pause or resume tiling"
    case .cycleWidth: "Cycle width"
    case .toggleFullWidth: "Full width"
    case .center: "Center the column"
    case .wider: "Wider"
    case .narrower: "Narrower"
    case .taller: "Taller"
    case .shorter: "Shorter"
    case .equalizeHeights: "Equalize heights"
    case .stackLeft: "Stack into left column"
    case .stackRight: "Stack into right column"
    case .popOutLeft: "Pop out to the left"
    case .popOutRight: "Pop out to the right"
    case .toggleTabbed: "Tabbed column"
    case .toggleFloating: "Float or unfloat"
    }
  }
}

extension Action {
  var commandName: String {
    rawValue.reduce(into: "") { name, character in
      if character.isUppercase { name.append("-") }
      name.append(contentsOf: character.lowercased())
    }
  }

  init?(commandName: String) {
    guard let action = Action.allCases.first(where: { $0.commandName == commandName }) else {
      return nil
    }
    self = action
  }
}
