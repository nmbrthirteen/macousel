import Foundation

extension Strip {
  func usableWidth(viewportWidth: Double, config: LayoutConfig) -> Double {
    viewportWidth - 2 * config.outerGap
  }

  func columnSpans(usableWidth: Double, innerGap: Double) -> [(x: Double, width: Double)] {
    var x = 0.0
    return columns.map { column in
      let width = column.pixelWidth(usableWidth: usableWidth, innerGap: innerGap)
      defer { x += width + innerGap }
      return (x, width)
    }
  }

  public func contentWidth(viewportWidth: Double, config: LayoutConfig) -> Double {
    let usable = usableWidth(viewportWidth: viewportWidth, config: config)
    guard let last = columnSpans(usableWidth: usable, innerGap: config.innerGap).last else {
      return 0
    }
    return last.x + last.width
  }

  public mutating func scrollToFocus(viewportWidth: Double, config: LayoutConfig) {
    guard let focused = focusedColumn else {
      scrollOffset = 0
      return
    }
    let usable = usableWidth(viewportWidth: viewportWidth, config: config)
    let spans = columnSpans(usableWidth: usable, innerGap: config.innerGap)
    let span = spans[focused]
    let content = spans[spans.count - 1].x + spans[spans.count - 1].width
    let maxOffset = max(0, content - usable)

    switch config.centerMode {
    case .never:
      var offset = scrollOffset
      if span.x < offset {
        offset = span.x
      } else if span.x + span.width > offset + usable {
        offset = span.x + span.width - usable
      }
      scrollOffset = min(max(offset, 0), maxOffset)
    case .onOverflow:
      let centred = span.x + span.width / 2 - usable / 2
      scrollOffset = content <= usable ? (content - usable) / 2 : centred
    case .always:
      scrollOffset = span.x + span.width / 2 - usable / 2
    }
  }

  public mutating func centerFocused(viewportWidth: Double, config: LayoutConfig) {
    guard let focused = focusedColumn else { return }
    let usable = usableWidth(viewportWidth: viewportWidth, config: config)
    let span = columnSpans(usableWidth: usable, innerGap: config.innerGap)[focused]
    scrollOffset = span.x + span.width / 2 - usable / 2
  }
}
