import AppKit

extension NSImage {
  // A bitmap at the sharpest backing scale of any screen. A drawing-handler image would keep
  // the full-size source alive, and app icons carry several representations.
  func resized(toSide side: Double) -> NSImage {
    let scale = NSScreen.screens.map(\.backingScaleFactor).max() ?? 2
    let pixels = Int((side * scale).rounded())
    guard
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB,
        bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: bitmap)
    else { return self }
    bitmap.size = NSSize(width: side, height: side)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    draw(in: NSRect(origin: .zero, size: bitmap.size))
    NSGraphicsContext.restoreGraphicsState()
    let image = NSImage(size: bitmap.size)
    image.addRepresentation(bitmap)
    return image
  }
}
