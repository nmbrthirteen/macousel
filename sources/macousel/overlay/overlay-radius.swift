enum OverlayRadius {
  static let window = Metrics.Radius.window
  static let minimapContainer = Metrics.Minimap.containerRadius
  static let card = concentric(outer: window, inset: Metrics.Spacing.tight)

  static func concentric(outer: Double, inset: Double) -> Double {
    max(outer - inset, Metrics.Radius.concentricFloor)
  }
}
