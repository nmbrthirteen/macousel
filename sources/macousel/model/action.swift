nonisolated enum Action: Hashable, Sendable {
  static let places = 1...9
  static let lastPlace = 9

  case focusLeft, focusRight, focusUp, focusDown
  case focusFirst, focusLast
  case focusColumn(Int)
  case moveLeft, moveRight, moveUp, moveDown
  case moveToColumn(Int)
  case moveToFirst, moveToLast
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

  case toggleOverview
  case sendToScratchpad, toggleScratchpad
}

nonisolated extension Action: CaseIterable {
  static let allCases: [Action] =
    [.focusLeft, .focusRight, .focusUp, .focusDown, .focusFirst, .focusLast]
    + places.map { .focusColumn($0) }
    + [.moveLeft, .moveRight, .moveUp, .moveDown]
    + places.map { .moveToColumn($0) }
    + [
      .moveToFirst, .moveToLast, .sendToNextDisplay, .togglePaused,
      .cycleWidth, .toggleFullWidth, .center, .wider, .narrower, .taller, .shorter,
      .equalizeHeights,
      .stackLeft, .stackRight, .popOutLeft, .popOutRight, .toggleTabbed, .toggleFloating,
      .toggleOverview, .sendToScratchpad, .toggleScratchpad,
    ]
}

nonisolated extension Action: RawRepresentable {
  var rawValue: String {
    switch self {
    case .focusColumn(let place): "focusColumn\(place)"
    case .moveToColumn(let place): "moveToColumn\(place)"
    default: String(describing: self)
    }
  }

  init?(rawValue: String) {
    guard let action = Action.allCases.first(where: { $0.rawValue == rawValue }) else {
      return nil
    }
    self = action
  }
}

nonisolated extension Action: Codable {
  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    guard let action = Action(rawValue: raw) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "Unknown action \(raw)"))
    }
    self = action
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

nonisolated extension Action {
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
