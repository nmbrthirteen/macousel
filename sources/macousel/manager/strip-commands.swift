import StripCore

enum StripCommandOutcome: Equatable {
  case applied
  case appliedKeepingScroll
  case blockedAtEdge(HorizontalDirection)
  case ignored
}

extension Strip {
  mutating func apply(
    _ action: Action, viewportWidth: Double, config: LayoutConfig
  ) -> StripCommandOutcome {
    switch action {
    case .focusLeft: focus(.left) ? .applied : .blockedAtEdge(.left)
    case .focusRight: focus(.right) ? .applied : .blockedAtEdge(.right)
    case .focusUp: outcome(focus(.up))
    case .focusDown: outcome(focus(.down))
    case .focusFirst: outcome(focusFirst())
    case .focusLast: outcome(focusLast())
    case .moveLeft: outcome(moveFocused(.left))
    case .moveRight: outcome(moveFocused(.right))
    case .moveUp: outcome(moveFocused(.up))
    case .moveDown: outcome(moveFocused(.down))
    case .cycleWidth: outcome(cycleWidth(config: config))
    case .wider: outcome(resizeWidth(by: config.widthStep, viewportWidth, config))
    case .narrower: outcome(resizeWidth(by: -config.widthStep, viewportWidth, config))
    case .taller: outcome(adjustHeight(by: config.heightStep))
    case .shorter: outcome(adjustHeight(by: -config.heightStep))
    case .stackLeft: outcome(stackFocused(into: .left))
    case .stackRight: outcome(stackFocused(into: .right))
    case .popOutLeft: outcome(popOutFocused(to: .left))
    case .popOutRight: outcome(popOutFocused(to: .right))
    case .toggleTabbed: outcome(toggleTabbed())
    case .toggleFullWidth: performing { $0.toggleFullWidth() }
    case .equalizeHeights: performing { $0.equalizeHeights() }
    case .center: centering(viewportWidth: viewportWidth, config: config)
    case .togglePaused, .toggleFloating, .sendToNextDisplay: .ignored
    }
  }

  private func outcome(_ changed: Bool) -> StripCommandOutcome {
    changed ? .applied : .ignored
  }

  private mutating func resizeWidth(
    by delta: Double, _ viewportWidth: Double, _ config: LayoutConfig
  ) -> Bool {
    adjustWidth(by: delta, viewportWidth: viewportWidth, config: config)
  }

  private mutating func performing(_ change: (inout Strip) -> Void) -> StripCommandOutcome {
    guard !isEmpty else { return .ignored }
    change(&self)
    return .applied
  }

  private mutating func centering(viewportWidth: Double, config: LayoutConfig)
    -> StripCommandOutcome
  {
    guard !isEmpty else { return .ignored }
    centerFocused(viewportWidth: viewportWidth, config: config)
    return .appliedKeepingScroll
  }
}
