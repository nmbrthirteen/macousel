import CoreGraphics

// Where the helper panel sits next to the System Settings window, in AppKit screen coordinates.
// Beside the window first, so the list it points at stays visible, then below it, then inside
// the screen's bottom trailing corner when nothing else fits.
nonisolated enum GuidePanelPlacement {
  static func origin(
    for panel: CGSize, beside window: CGRect, within screen: CGRect, gap: CGFloat
  ) -> CGPoint {
    let top = min(window.maxY, screen.maxY) - panel.height
    let trailing = CGPoint(x: window.maxX + gap, y: top)
    if screen.contains(CGRect(origin: trailing, size: panel)) { return trailing }
    let leading = CGPoint(x: window.minX - gap - panel.width, y: top)
    if screen.contains(CGRect(origin: leading, size: panel)) { return leading }
    let below = CGPoint(x: window.midX - panel.width / 2, y: window.minY - gap - panel.height)
    if screen.contains(CGRect(origin: below, size: panel)) { return below }
    return CGPoint(x: screen.maxX - gap - panel.width, y: screen.minY + gap)
  }
}
