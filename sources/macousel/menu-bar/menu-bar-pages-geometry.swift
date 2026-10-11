import CoreGraphics

nonisolated struct MenuBarPagesGeometry: Equatable {
  struct Page: Equatable {
    let rect: CGRect
    let rows: [CGRect]
    let isActive: Bool
    let number: Int?
    let opacity: Double
  }

  static let pageHeight = 13.0
  static let minimumPageWidth = 7.0
  static let maximumPageWidth = 18.0
  static let widthPerShare = 36.0
  static let pageGap = 2.0
  static let rowGap = 1.0
  static let rowLimit = 4
  static let maximumWidth = 120.0
  static let highestNumber = 9
  static let cutOffOpacity = 0.35

  let size: CGSize
  let pages: [Page]

  init?(position: StripPosition) {
    guard position.pages.indices.contains(position.focusedIndex) else { return nil }
    let widths = position.pages.map(Self.width(of:))
    let visible = Self.visibleRange(widths: widths, active: position.focusedIndex)
    var x = 0.0
    pages = visible.map { index in
      let rect = CGRect(x: x, y: 0, width: widths[index], height: Self.pageHeight)
      x += widths[index] + Self.pageGap
      let isActive = index == position.focusedIndex
      let isCutOff = !isActive && (index == visible.first && index > 0
        || index == visible.last && index < widths.count - 1)
      return Page(
        rect: rect, rows: Self.rows(count: position.pages[index].rowCount, in: rect),
        isActive: isActive,
        number: isActive && index < Self.highestNumber ? index + 1 : nil,
        opacity: isCutOff ? Self.cutOffOpacity : 1)
    }
    size = CGSize(width: max(x - Self.pageGap, 0), height: Self.pageHeight)
  }

  private static func width(of page: StripPosition.Page) -> Double {
    let raw = min(max(page.widthShare * widthPerShare, minimumPageWidth), maximumPageWidth)
    return (raw * 2).rounded() / 2
  }

  private static func visibleRange(widths: [Double], active: Int) -> ClosedRange<Int> {
    var low = active
    var high = active
    var used = widths[active]
    var grew = true
    while grew {
      grew = false
      if low > 0, used + pageGap + widths[low - 1] <= maximumWidth {
        low -= 1
        used += pageGap + widths[low]
        grew = true
      }
      if high < widths.count - 1, used + pageGap + widths[high + 1] <= maximumWidth {
        high += 1
        used += pageGap + widths[high]
        grew = true
      }
    }
    return low...high
  }

  private static func rows(count: Int, in rect: CGRect) -> [CGRect] {
    let rows = min(max(count, 1), rowLimit)
    let height = (rect.height - Double(rows - 1) * rowGap) / Double(rows)
    return (0..<rows).map {
      CGRect(
        x: rect.minX, y: rect.minY + Double($0) * (height + rowGap), width: rect.width,
        height: height)
    }
  }
}
