import CoreGraphics

enum MinimapConcentricRadius {
  static func radius(of rect: CGRect, in container: CGSize) -> Double {
    let inset = max(
      min(rect.minX, rect.minY, container.width - rect.maxX, container.height - rect.maxY), 0)
    return OverlayRadius.concentric(outer: OverlayRadius.minimapContainer, inset: inset)
  }
}
