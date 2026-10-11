enum Action: String, CaseIterable, Codable, Sendable {
  case focusLeft, focusRight, focusUp, focusDown
  case focusFirst, focusLast
  case focusColumn1, focusColumn2, focusColumn3, focusColumn4, focusColumn5
  case focusColumn6, focusColumn7, focusColumn8, focusColumn9
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
      .focusColumn1, .focusColumn2, .focusColumn3, .focusColumn4, .focusColumn5,
      .focusColumn6, .focusColumn7, .focusColumn8, .focusColumn9,
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
    case .focusColumn1: "Focus column 1"
    case .focusColumn2: "Focus column 2"
    case .focusColumn3: "Focus column 3"
    case .focusColumn4: "Focus column 4"
    case .focusColumn5: "Focus column 5"
    case .focusColumn6: "Focus column 6"
    case .focusColumn7: "Focus column 7"
    case .focusColumn8: "Focus column 8"
    case .focusColumn9: "Focus column 9"
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
  static let columnActions: [Action] = [
    .focusColumn1, .focusColumn2, .focusColumn3, .focusColumn4, .focusColumn5,
    .focusColumn6, .focusColumn7, .focusColumn8, .focusColumn9,
  ]

  var columnIndex: Int? { Self.columnActions.firstIndex(of: self) }

  var commandName: String {
    rawValue.reduce(into: "") { name, character in
      if character.isUppercase || character.isNumber { name.append("-") }
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
