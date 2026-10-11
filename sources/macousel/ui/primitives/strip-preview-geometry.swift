import CoreGraphics
import StripCore

struct StripPreviewGeometry: Equatable {
  let container: CGSize
  let displayRect: CGRect
  let scale: Double
  let windows: [PreviewWindow]
  let leadingFade: CGRect
  let trailingFade: CGRect

  init(
    scenario: StripPreviewScenario, config: LayoutConfig, container: CGSize,
    screenSize: CGSize = PreviewMetrics.screenSize, showsOverflow: Bool = true
  ) {
    self.container = container
    displayRect =
      showsOverflow
      ? Self.fittedDisplay(aspect: screenSize.width / screenSize.height, in: container)
      : CGRect(origin: .zero, size: container)
    scale = displayRect.width / screenSize.width
    let strip = scenario.strip(viewportWidth: screenSize.width, config: config)
    let layout = strip.layout(in: CGRect(origin: .zero, size: screenSize), config: config)
    let bounds = CGRect(origin: .zero, size: container)
    let origin = displayRect.origin
    let scale = scale
    windows = layout.placements.compactMap { placement in
      guard !placement.isBehindTab else { return nil }
      let frame = placement.frame
      let rect = CGRect(
        x: origin.x + frame.minX * scale, y: origin.y + frame.minY * scale,
        width: frame.width * scale, height: frame.height * scale)
      guard rect.intersects(bounds) else { return nil }
      return PreviewWindow(
        id: placement.window, rect: rect, isFocused: placement.isFocused,
        column: placement.column, row: placement.row)
    }
    let displayRect = displayRect
    leadingFade = CGRect(x: 0, y: 0, width: displayRect.minX, height: container.height)
    trailingFade = CGRect(
      x: displayRect.maxX, y: 0, width: container.width - displayRect.maxX,
      height: container.height)
  }

  func cardRect(_ card: FloatingPreviewCard) -> CGRect {
    CGRect(
      x: displayRect.minX + card.unitFrame.minX * displayRect.width,
      y: displayRect.minY + card.unitFrame.minY * displayRect.height,
      width: card.unitFrame.width * displayRect.width,
      height: card.unitFrame.height * displayRect.height)
  }

  func borderLineWidth(for points: Double) -> Double {
    points * PreviewMetrics.borderWidthScale
  }

  private static func fittedDisplay(aspect: Double, in container: CGSize) -> CGRect {
    let maxWidth = container.width - 2 * PreviewMetrics.horizontalInset
    let maxHeight = container.height - 2 * PreviewMetrics.verticalInset
    let height = min(maxHeight, maxWidth / aspect)
    let width = height * aspect
    return CGRect(
      x: (container.width - width) / 2, y: (container.height - height) / 2, width: width,
      height: height)
  }
}
