import Foundation

extension Strip {
  static let widthFractionRange = 0.1...1.0

  @discardableResult
  public mutating func cycleWidth(config: LayoutConfig) -> Bool {
    guard let focused = focusedColumn, !config.presetWidths.isEmpty else { return false }
    let presets = config.presetWidths.sorted()
    let current: Double
    switch columns[focused].width {
    case .fraction(let fraction): current = columns[focused].isFullWidth ? 1.0 : fraction
    case .fixed: current = 0
    }
    let next = presets.first { $0 > current + 1e-6 } ?? presets[0]
    columns[focused].width = .fraction(next)
    columns[focused].isFullWidth = false
    return true
  }

  public mutating func toggleFullWidth() {
    guard let focused = focusedColumn else { return }
    columns[focused].isFullWidth.toggle()
  }

  @discardableResult
  public mutating func adjustWidth(
    by delta: Double, viewportWidth: Double, config: LayoutConfig
  ) -> Bool {
    guard let focused = focusedColumn else { return false }
    let column = columns[focused]
    let usable = viewportWidth - 2 * config.outerGap
    let current: Double
    switch column.width {
    case .fraction(let fraction):
      current = column.isFullWidth ? 1.0 : fraction
    case .fixed(let points):
      current = (points + config.innerGap) / (usable + config.innerGap)
    }
    let range = Strip.widthFractionRange
    let next = min(max(current + delta, range.lowerBound), range.upperBound)
    let changed = column.isFullWidth || abs(next - current) > 1e-9 || column.width != .fraction(next)
    guard changed else { return false }
    columns[focused].width = .fraction(next)
    columns[focused].isFullWidth = false
    return true
  }

  public mutating func setFixedWidth(_ points: Double, of window: WindowID) {
    guard let (columnIndex, _) = location(of: window) else { return }
    columns[columnIndex].width = .fixed(points)
    columns[columnIndex].isFullWidth = false
  }

  public mutating func setFullWidth(_ isFullWidth: Bool, of window: WindowID) {
    guard let (columnIndex, _) = location(of: window) else { return }
    columns[columnIndex].isFullWidth = isFullWidth
  }

  @discardableResult
  public mutating func adjustHeight(by delta: Double) -> Bool {
    guard let focused = focusedColumn else { return false }
    return columns[focused].adjustActiveHeight(by: delta)
  }

  public mutating func equalizeHeights() {
    guard let focused = focusedColumn else { return }
    columns[focused].equalizeHeights()
  }
}
