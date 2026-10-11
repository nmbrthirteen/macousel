import CoreGraphics
import StripCore

struct SavedColumn: Codable {
  struct Window: Codable {
    var bundleIdentifier: String?
    var title: String
  }

  var width: ColumnWidth
  var display: ColumnDisplay
  var windows: [Window]
  var heightWeights: [Double]?
  var isFullWidth: Bool?
}

extension SavedColumn {
  init(
    _ column: Column, windows: [CGWindowID: any WindowHandle], titles: [CGWindowID: String]
  ) {
    self.init(
      width: column.width,
      display: column.display,
      windows: column.windows.compactMap { id in
        windows[id.rawValue].map { Window($0, title: titles[id.rawValue] ?? "") }
      },
      heightWeights: column.heightWeights,
      isFullWidth: column.isFullWidth)
  }
}

extension SavedColumn.Window {
  init(_ window: any WindowHandle, title: String) {
    self.init(bundleIdentifier: window.bundleIdentifier, title: title)
  }
}
