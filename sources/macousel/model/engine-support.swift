nonisolated enum EngineSupport: Equatable, Sendable {
  case command(PaneruCommand)
  case handledByMacousel
  case builtInOnly
}

nonisolated extension Action {
  var paneruSupport: EngineSupport {
    switch self {
    case .focusLeft: .command(PaneruCommand("window", "focus", "west"))
    case .focusRight: .command(PaneruCommand("window", "focus", "east"))
    case .focusUp: .command(PaneruCommand("window", "focus", "north"))
    case .focusDown: .command(PaneruCommand("window", "focus", "south"))
    case .focusFirst: .command(PaneruCommand("window", "focus", "first"))
    case .focusLast: .command(PaneruCommand("window", "focus", "last"))
    case .focusColumn(let place): .command(Self.focusColumnCommand(place))
    case .moveLeft: .command(PaneruCommand("window", "swap", "west"))
    case .moveRight: .command(PaneruCommand("window", "swap", "east"))
    case .moveUp: .command(PaneruCommand("window", "swap", "north"))
    case .moveDown: .command(PaneruCommand("window", "swap", "south"))
    case .moveToFirst: .command(PaneruCommand("window", "swap", "first"))
    case .moveToLast: .command(PaneruCommand("window", "swap", "last"))
    case .sendToNextDisplay: .command(PaneruCommand("window", "nextdisplay"))
    case .cycleWidth: .command(PaneruCommand("window", "resize"))
    case .toggleFullWidth: .command(PaneruCommand("window", "fullwidth"))
    case .center: .command(PaneruCommand("window", "center"))
    case .wider: .command(PaneruCommand("window", "grow"))
    case .narrower: .command(PaneruCommand("window", "shrink"))
    case .taller: .command(PaneruCommand("window", "vertical", "grow"))
    case .shorter: .command(PaneruCommand("window", "vertical", "shrink"))
    case .equalizeHeights: .command(PaneruCommand("window", "equalize"))
    case .stackLeft, .stackRight: .command(PaneruCommand("window", "stack"))
    case .popOutLeft, .popOutRight: .command(PaneruCommand("window", "unstack"))
    case .toggleTabbed: .command(PaneruCommand("window", "tabbeddisplay"))
    case .toggleFloating: .command(PaneruCommand("window", "manage"))
    case .togglePaused, .toggleOverview: .handledByMacousel
    case .moveToColumn, .sendToScratchpad, .toggleScratchpad: .builtInOnly
    }
  }

  func isSupported(by engine: WindowEngine) -> Bool {
    switch engine {
    case .builtIn: true
    case .paneru: paneruSupport != .builtInOnly
    }
  }

  private static func focusColumnCommand(_ place: Int) -> PaneruCommand {
    place == lastPlace
      ? PaneruCommand("window", "focus", "last") : PaneruCommand("window", "focus", "\(place)")
  }
}
