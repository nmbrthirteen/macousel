import CoreGraphics

enum MinimapConcentricRadius {
  static func radius(of rect: CGRect, in container: CGSize) -> Double {
    let inset = max(
      min(rect.minX, rect.minY, container.width - rect.maxX, container.height - rect.maxY), 0)
    return max(Metrics.Minimap.containerRadius - inset, Metrics.Minimap.concentricRadiusFloor)
  }
}
