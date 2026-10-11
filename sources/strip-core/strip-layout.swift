import CoreGraphics
import Foundation

public struct Placement: Sendable, Equatable {
  public enum Visibility: Sendable, Equatable {
    case full, partial, offscreen(HorizontalDirection)
  }

  public var window: WindowID
  public var frame: CGRect
  public var visibility: Visibility
  public var column: Int
  public var row: Int
  public var isBehindTab: Bool
  public var isFocused: Bool
}

public struct StripLayout: Sendable, Equatable {
  public var placements: [Placement]
  public var contentWidth: Double

  public subscript(window: WindowID) -> Placement? {
    placements.first { $0.window == window }
  }
}

extension Strip {
  public func layout(
    in viewport: CGRect, config: LayoutConfig, scrollOffset: Double? = nil
  ) -> StripLayout {
    let offset = scrollOffset ?? self.scrollOffset
    let usable = usableWidth(viewportWidth: viewport.width, config: config)
    let height = viewport.height - 2 * config.outerGap
    let spans = columnSpans(usableWidth: usable, innerGap: config.innerGap)
    var placements: [Placement] = []

    for (index, column) in columns.enumerated() {
      let span = spans[index]
      let minX = (viewport.minX + config.outerGap + span.x - offset).rounded()
      let top = viewport.minY + config.outerGap
      let rows = rowSpans(of: column, top: top, height: height, config: config)

      for (row, window) in column.windows.enumerated() {
        let frame = CGRect(x: minX, y: rows[row].minY, width: span.width, height: rows[row].height)
        placements.append(
          Placement(
            window: window,
            frame: frame,
            visibility: Strip.visibility(of: frame, in: viewport),
            column: index,
            row: row,
            isBehindTab: column.display == .tabbed && column.windows.count > 1
              && row != column.activeRow,
            isFocused: index == focusedColumn && row == column.activeRow))
      }
    }
    return StripLayout(
      placements: placements,
      contentWidth: contentWidth(viewportWidth: viewport.width, config: config))
  }

  private func rowSpans(
    of column: Column, top: Double, height: Double, config: LayoutConfig
  ) -> [(minY: Double, height: Double)] {
    let count = column.windows.count
    if count > 1 && column.display == .tabbed {
      let tabbed = (top + config.tabBarHeight).rounded()
      let bottom = (top + height).rounded()
      return Array(repeating: (tabbed, bottom - tabbed), count: count)
    }
    let available = height - Double(count - 1) * config.innerGap
    let weightTotal = column.heightWeights.reduce(0, +)
    var cursor = top
    return column.heightWeights.map { weight in
      let rowHeight = available * weight / weightTotal
      defer { cursor += rowHeight + config.innerGap }
      let minY = cursor.rounded()
      return (minY, (cursor + rowHeight).rounded() - minY)
    }
  }

  static func visibility(of frame: CGRect, in viewport: CGRect) -> Placement.Visibility {
    if frame.maxX <= viewport.minX { return .offscreen(.left) }
    if frame.minX >= viewport.maxX { return .offscreen(.right) }
    if frame.minX >= viewport.minX && frame.maxX <= viewport.maxX { return .full }
    return .partial
  }
}
