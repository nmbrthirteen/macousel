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
  init(_ column: Column, windows: [CGWindowID: any WindowHandle]) {
    self.init(
      width: column.width,
      display: column.display,
      windows: column.windows.compactMap { windows[$0.rawValue].map(Window.init) },
      heightWeights: column.heightWeights,
      isFullWidth: column.isFullWidth)
  }
}

extension SavedColumn.Window {
  init(_ window: any WindowHandle) {
    self.init(bundleIdentifier: window.bundleIdentifier, title: window.title)
  }
}
