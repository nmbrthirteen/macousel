import Foundation

extension Strip {
  private static let fullyVisibleTolerance = 0.5

  public mutating func settle(at offset: Double, viewportWidth: Double, config: LayoutConfig) {
    guard !isEmpty else {
      scrollOffset = 0
      return
    }
    if config.centerMode == .always {
      settleOnNearestCentre(at: offset, viewportWidth: viewportWidth, config: config)
    } else {
      settleOnNearestLeftEdge(at: offset, viewportWidth: viewportWidth, config: config)
    }
  }

  private mutating func settleOnNearestCentre(
    at offset: Double, viewportWidth: Double, config: LayoutConfig
  ) {
    scrollOffset = offset
    let usable = usableWidth(viewportWidth: viewportWidth, config: config)
    focusedColumn = columnNearestCentre(of: offset, usable: usable, config: config)
    scrollToFocus(viewportWidth: viewportWidth, config: config)
  }

  private mutating func settleOnNearestLeftEdge(
    at offset: Double, viewportWidth: Double, config: LayoutConfig
  ) {
    let usable = usableWidth(viewportWidth: viewportWidth, config: config)
    let spans = columnSpans(usableWidth: usable, innerGap: config.innerGap)
    let furthest = max(0, contentWidth(viewportWidth: viewportWidth, config: config) - usable)
    let candidates = spans.map { min(max($0.x, 0), furthest) }
    let resting = candidates.min { abs($0 - offset) < abs($1 - offset) } ?? 0
    scrollOffset = resting

    let tolerance = Self.fullyVisibleTolerance
    let fullyVisible = spans.indices.filter {
      spans[$0].x >= resting - tolerance
        && spans[$0].x + spans[$0].width <= resting + usable + tolerance
    }
    if let focused = focusedColumn, fullyVisible.contains(focused) { return }
    focusedColumn =
      fullyVisible.first ?? columnNearestCentre(of: resting, usable: usable, config: config)
  }

  private func columnNearestCentre(of offset: Double, usable: Double, config: LayoutConfig)
    -> Int?
  {
    let centre = offset + usable / 2
    let spans = columnSpans(usableWidth: usable, innerGap: config.innerGap)
    return spans.indices.min {
      abs(spans[$0].x + spans[$0].width / 2 - centre)
        < abs(spans[$1].x + spans[$1].width / 2 - centre)
    }
  }
}
