import CoreGraphics

enum MinimapPanelFrame {
  static func frame(containerWidth: Double, on displayFrame: CGRect) -> CGRect {
    CGRect(
      x: displayFrame.midX - containerWidth / 2,
      y: displayFrame.maxY - Metrics.Spacing.spacious - Metrics.Minimap.height,
      width: containerWidth, height: Metrics.Minimap.height)
  }
}
