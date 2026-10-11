import CoreGraphics

enum MinimapCellContent: Equatable {
  case icon(bundleIdentifier: String)
  case number(Int)
  case none

  init(size: CGSize, columnNumber: Int, showsNumber: Bool, bundleIdentifier: String?) {
    if let bundleIdentifier, size.width >= Metrics.Minimap.iconMinimumWidth,
      size.height >= Metrics.Minimap.iconMinimumHeight
    {
      self = .icon(bundleIdentifier: bundleIdentifier)
    } else if showsNumber, columnNumber <= Metrics.Minimap.highestNumberedColumn,
      size.width >= Metrics.Minimap.numberMinimumWidth,
      size.height >= Metrics.Minimap.numberMinimumHeight
    {
      self = .number(columnNumber)
    } else {
      self = .none
    }
  }
}
