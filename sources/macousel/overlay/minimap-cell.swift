import CoreGraphics
import StripCore

struct MinimapCell: Identifiable, Equatable {
  let id: WindowID
  let rect: CGRect
  let isFocused: Bool
  let content: MinimapCellContent
  let contentCenter: CGPoint
  let tabDots: [CGRect]

  init(
    id: WindowID, rect: CGRect, isFocused: Bool, columnNumber: Int, isLeadRow: Bool,
    dotCount: Int, bundleIdentifier: String?
  ) {
    self.id = id
    self.rect = rect
    self.isFocused = isFocused
    tabDots = Self.dots(count: dotCount, in: rect)
    let contentBottom =
      tabDots.first.map { $0.minY - Metrics.Minimap.tabDotGap } ?? rect.maxY
    let contentArea = CGRect(
      x: rect.minX, y: rect.minY, width: rect.width, height: contentBottom - rect.minY)
    content = MinimapCellContent(
      size: contentArea.size, columnNumber: columnNumber, showsNumber: isLeadRow,
      bundleIdentifier: bundleIdentifier)
    contentCenter = CGPoint(x: contentArea.midX, y: contentArea.midY)
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
