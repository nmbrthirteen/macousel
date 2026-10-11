import AppKit

extension NSImage {
  func resized(toSide side: Double) -> NSImage {
    NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
      self.draw(in: rect)
      return true
    }
  }
}
