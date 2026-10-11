import AppKit

enum MenuBarPillImage {
  private static let restingAlpha = 0.45
  private static let cornerRadius = 1.5

  static func make(_ geometry: MenuBarPillGeometry) -> NSImage {
    let image = NSImage(size: geometry.size, flipped: true) { _ in
      for pill in geometry.pills {
        NSColor.black.withAlphaComponent(pill.isFocused ? 1 : restingAlpha).setFill()
        for segment in pill.segments {
          NSBezierPath(roundedRect: segment, xRadius: cornerRadius, yRadius: cornerRadius).fill()
        }
      }
      return true
    }
    image.isTemplate = true
    return image
  }
}
