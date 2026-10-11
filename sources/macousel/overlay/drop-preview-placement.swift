import CoreGraphics

struct DropPreviewPlacement {
  let area: CGRect

  func localFrame(of frame: CGRect) -> CGRect {
    frame.offsetBy(dx: -area.minX, dy: -area.minY)
  }
}
