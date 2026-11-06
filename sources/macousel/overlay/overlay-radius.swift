enum OverlayRadius {
  static let window = Metrics.Radius.window
  static let minimapContainer = Metrics.Minimap.containerRadius

  static func overviewCard(scale: Double) -> Double {
    max(window * scale, Metrics.Radius.concentricFloor)
  }

  static func concentric(outer: Double, inset: Double) -> Double {
    max(outer - inset, Metrics.Radius.concentricFloor)
  }
}
