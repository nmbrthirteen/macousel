import AppKit

enum MenuBarPagesImage {
  private static let outlineWidth = 1.0
  private static let outlineOpacity = 0.55
  private static let numberSize = 8.5

  static func make(_ geometry: MenuBarPagesGeometry) -> NSImage {
    let image = NSImage(size: geometry.size, flipped: true) { _ in
      for page in geometry.pages {
        if page.isActive { fill(page) } else { outline(page) }
      }
      return true
    }
    image.isTemplate = true
    return image
  }

  private static func radius(for row: CGRect) -> Double {
    MenuBarPagesGeometry.cornerRadius(forRowHeight: row.height)
  }

  private static func fill(_ page: MenuBarPagesGeometry.Page) {
    NSColor.black.withAlphaComponent(page.opacity).setFill()
    for row in page.rows {
      NSBezierPath(roundedRect: row, xRadius: radius(for: row), yRadius: radius(for: row)).fill()
    }
    if let number = page.number { cutOut(number, in: page.rect) }
  }

  private static func outline(_ page: MenuBarPagesGeometry.Page) {
    NSColor.black.withAlphaComponent(outlineOpacity * page.opacity).setStroke()
    for row in page.rows {
      let inset = row.insetBy(dx: outlineWidth / 2, dy: outlineWidth / 2)
      let path = NSBezierPath(
        roundedRect: inset, xRadius: radius(for: inset), yRadius: radius(for: inset))
      path.lineWidth = outlineWidth
      path.stroke()
    }
  }

  private static var numberFont: NSFont {
    let base = NSFont.monospacedDigitSystemFont(ofSize: numberSize, weight: .bold)
    return base.fontDescriptor.withDesign(.rounded).flatMap {
      NSFont(descriptor: $0, size: numberSize)
    } ?? base
  }

  private static func cutOut(_ number: Int, in rect: CGRect) {
    let font = numberFont
    let text = NSAttributedString(
      string: "\(number)", attributes: [.font: font, .foregroundColor: NSColor.black])
    let size = text.size()
    let top = rect.midY - font.ascender + font.capHeight / 2
    guard let context = NSGraphicsContext.current else { return }
    context.saveGraphicsState()
    context.compositingOperation = .destinationOut
    text.draw(at: CGPoint(x: rect.midX - size.width / 2, y: top))
    context.restoreGraphicsState()
  }
}
