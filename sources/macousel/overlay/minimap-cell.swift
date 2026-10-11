import CoreGraphics
import StripCore

struct MinimapCell: Identifiable, Equatable {
  let id: WindowID
  let window: WindowID
  let column: Int
  let row: Int
  let rect: CGRect
  let cornerRadius: Double
  let isFocused: Bool
  let content: MinimapCellContent
  let tabDots: [CGRect]

  init(
    id: WindowID, window: WindowID, column: Int, row: Int, rect: CGRect, isFocused: Bool,
    isLeadRow: Bool, dotCount: Int, bundleIdentifier: String?, containerSize: CGSize,
    isStacked: Bool
  ) {
    self.id = id
    self.window = window
    self.column = column
    self.row = row
    self.rect = rect
    let concentricRadius = MinimapConcentricRadius.radius(of: rect, in: containerSize)
    cornerRadius =
      isStacked
      ? min(concentricRadius, rect.height * Metrics.Minimap.stackedRowRadiusShare)
      : concentricRadius
    self.isFocused = isFocused
    tabDots = Self.dots(count: dotCount, in: rect)
    let contentBottom =
      tabDots.first.map { $0.minY - Metrics.Minimap.tabDotGap } ?? rect.maxY
    let contentArea = CGRect(
      x: rect.minX, y: rect.minY, width: rect.width, height: contentBottom - rect.minY)
    content = MinimapCellContent(
      area: contentArea, columnNumber: column + 1, isLeadRow: isLeadRow,
      bundleIdentifier: bundleIdentifier)
  }

  var hitRect: CGRect {
    rect.insetBy(dx: -Metrics.Minimap.columnGap / 2, dy: -Metrics.Minimap.rowGap / 2)
  }

  func isUpperHalf(at point: CGPoint) -> Bool {
    point.y < rect.midY
  }

  private static func dots(count: Int, in rect: CGRect) -> [CGRect] {
    let diameter = Metrics.Minimap.tabDotDiameter
    let gap = Metrics.Minimap.tabDotGap
    let rowWidth = Double(count) * diameter + Double(max(count - 1, 0)) * gap
    guard count > 0, rect.width >= rowWidth else { return [] }
    let top = rect.maxY - Metrics.Minimap.tabDotInset - diameter
    let left = rect.midX - rowWidth / 2
    return (0..<count).map {
      CGRect(x: left + Double($0) * (diameter + gap), y: top, width: diameter, height: diameter)
    }
  }
}
