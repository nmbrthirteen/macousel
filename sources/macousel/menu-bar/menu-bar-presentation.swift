nonisolated struct MenuBarPresentation: Equatable {
  enum Content: Equatable {
    case symbol(String)
    case pills(StripPosition)
    case pages(StripPosition)
    case symbolWithCount(symbol: String, text: String)
  }

  static let symbolName = "rectangle.split.3x1"
  static let pausedSymbolName = "pause.rectangle"

  let content: Content
  let accessibilityLabel: String

  init(
    status: WindowManager.Status, position: StripPosition?, indicator: MenuBarIndicator
  ) {
    switch (status, position) {
    case (.needsPermission, _):
      content = .symbol(Self.symbolName)
      accessibilityLabel = "Macousel, needs Accessibility access"
    case (.paused, _):
      content = .symbol(Self.pausedSymbolName)
      accessibilityLabel = "Macousel, paused"
    case (.running, nil):
      content = .symbol(Self.symbolName)
      accessibilityLabel = "Macousel"
    case (.running, let position?):
      content = Self.content(for: position, indicator: indicator)
      accessibilityLabel = "Macousel, column \(position.columnNumber) of \(position.columnCount)"
    }
  }

  private static func content(for position: StripPosition, indicator: MenuBarIndicator)
    -> Content
  {
    switch indicator {
    case .icon:
      return .symbol(symbolName)
    case .position where MenuBarPillGeometry(position: position) != nil:
      return .pills(position)
    case .pages where MenuBarPagesGeometry(position: position) != nil:
      return .pages(position)
    case .position, .pages, .count:
      return .symbolWithCount(
        symbol: symbolName, text: "\(position.columnNumber)/\(position.columnCount)")
    }
  }
}
