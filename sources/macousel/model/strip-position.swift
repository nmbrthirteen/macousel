import CoreGraphics
import StripCore

nonisolated struct StripPosition: Equatable, Sendable {
  struct Page: Equatable, Sendable {
    let widthShare: Double
    let rowCount: Int
  }

  static let placeholderWidthShare = 0.5

  let pages: [Page]
  let focusedIndex: Int

  var columnCount: Int { pages.count }
  var columnNumber: Int { focusedIndex + 1 }
  var windowsInFocusedColumn: Int {
    pages.indices.contains(focusedIndex) ? pages[focusedIndex].rowCount : 1
  }

  init(pages: [Page], focusedIndex: Int) {
    self.pages = pages
    self.focusedIndex = focusedIndex
  }

  init(columnCount: Int, focusedIndex: Int, windowsInFocusedColumn: Int) {
    self.init(
      pages: (0..<max(columnCount, 0)).map {
        Page(
          widthShare: Self.placeholderWidthShare,
          rowCount: $0 == focusedIndex ? windowsInFocusedColumn : 1)
      },
      focusedIndex: focusedIndex)
  }

  init?(strip: Strip, layout: StripLayout?, usableWidth: Double) {
    guard let focused = strip.focusedColumn, strip.columns.indices.contains(focused) else {
      return nil
    }
    let widths = Dictionary(
      layout?.placements.map { ($0.column, Double($0.frame.width)) } ?? [],
      uniquingKeysWith: { first, _ in first })
    self.init(
      pages: strip.columns.indices.map { index in
        Page(
          widthShare: usableWidth > 0
            ? widths[index].map { $0 / usableWidth } ?? Self.placeholderWidthShare
            : Self.placeholderWidthShare,
          rowCount: strip.columns[index].windows.count)
      },
      focusedIndex: focused)
  }
}
