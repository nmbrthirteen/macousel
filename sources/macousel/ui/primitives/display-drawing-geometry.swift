import CoreGraphics
import WindowSystem

struct DisplayDrawingGeometry: Equatable {
  struct Item: Equatable, Identifiable {
    let id: String
    let name: String
    let screenRect: CGRect
    let contentRect: CGRect
    let labelRect: CGRect
    let isTiled: Bool
  }

  let items: [Item]
  let scale: Double

  init(displays: [Display], disabled: Set<String>, container: CGSize) {
    guard let first = displays.first else {
      items = []
      scale = 0
      return
    }
    let union = displays.dropFirst().reduce(first.frame) { $0.union($1.frame) }
    let availableWidth = container.width - 2 * PreviewMetrics.Displays.horizontalInset
    let availableHeight = container.height - 2 * PreviewMetrics.Displays.verticalInset
    let scale = min(availableWidth / union.width, availableHeight / union.height)
    self.scale = scale
    let origin = CGPoint(
      x: (container.width - union.width * scale) / 2 - union.minX * scale,
      y: (container.height - union.height * scale) / 2 - union.minY * scale)
    items = displays.map { display in
      let screen = CGRect(
        x: origin.x + display.frame.minX * scale, y: origin.y + display.frame.minY * scale,
        width: display.frame.width * scale, height: display.frame.height * scale)
      return Self.item(for: display, screen: screen, isTiled: !disabled.contains(display.uuid))
    }
  }

  private static func item(for display: Display, screen: CGRect, isTiled: Bool) -> Item {
    let inset = PreviewMetrics.Displays.contentInset
    let band = PreviewMetrics.Displays.labelHeight
    let inner = screen.insetBy(dx: inset, dy: inset)
    let label = CGRect(x: inner.minX, y: inner.maxY - band, width: inner.width, height: band)
    let content = CGRect(
      x: inner.minX, y: inner.minY, width: inner.width, height: max(inner.height - band, 0))
    return Item(
      id: display.uuid, name: display.name, screenRect: screen, contentRect: content,
      labelRect: label, isTiled: isTiled)
  }
}
