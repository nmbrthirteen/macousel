nonisolated extension Action {
  var title: String {
    switch self {
    case .focusLeft: "Focus left"
    case .focusRight: "Focus right"
    case .focusUp: "Focus up"
    case .focusDown: "Focus down"
    case .focusFirst: "Focus first window"
    case .focusLast: "Focus last window"
    case .focusColumn(let place): "Focus \(Self.placeName(place))"
    case .moveLeft: "Move left"
    case .moveRight: "Move right"
    case .moveUp: "Move up"
    case .moveDown: "Move down"
    case .moveToColumn(let place): "Move to \(Self.placeName(place))"
    case .moveToFirst: "Move to first column"
    case .moveToLast: "Move to last column"
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
    case .stackLeft: "Stack with the column on the left"
    case .stackRight: "Stack with the column on the right"
    case .popOutLeft: "Pop out to the left"
    case .popOutRight: "Pop out to the right"
    case .toggleTabbed: "Tabbed column"
    case .toggleFloating: "Float or unfloat"
    case .toggleOverview: "Show or hide overview"
    case .sendToScratchpad: "Send window to scratchpad"
    case .toggleScratchpad: "Show or hide scratchpad"
    }
  }

  private static func placeName(_ place: Int) -> String {
    place == lastPlace ? "column \(place) (last)" : "column \(place)"
  }
}
