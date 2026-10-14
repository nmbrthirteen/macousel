import CoreGraphics

enum OnboardingSceneMetrics {
  static let size = CGSize(width: OnboardingMetrics.width, height: OnboardingMetrics.heroHeight)
  static let menuBarHeight = 24.0
  static let edgeGap = 10.0
  static let columnGap = 8.0
  static let windowTop = menuBarHeight + edgeGap
  static let windowHeight = 206.0
  static let windowRadius = 9.0
  static let titleBarHeight = 18.0
  static let overviewScale = 0.82
  static let focusedWidthShare = 0.75

  static let settingsCard = CGRect(x: 110, y: 52, width: 240, height: 112)
  static let settingsRowInset = 12.0
  static let settingsRowHeight = 30.0
  static let toggleSize = CGSize(width: 28, height: 16)

  static var toggleCenter: CGPoint {
    CGPoint(
      x: settingsCard.maxX - settingsRowInset - toggleSize.width / 2,
      y: settingsCard.maxY - settingsRowInset - settingsRowHeight / 2)
  }

  static let menuBarInset = 12.0
  static let menuBarSpacing = 6.0
  static let statusItemWidth = 22.0
  static let clockWidth = 58.0
  static let statusItemCount = 4
  static let appItemWidth = 100.0
  static let menuWidth = 168.0
  static let menuRowHeight = 22.0
  static let menuPadding = 5.0
  static let menuItems = ["Pause tiling", "Settings…", "Show welcome guide", "Quit Macousel"]
  static let settingsItem = 1

  static var usableWidth: Double { size.width - edgeGap * 2 }

  static var appItem: CGRect {
    let trailing = size.width - menuBarInset - clockWidth
      - Double(statusItemCount) * (statusItemWidth + menuBarSpacing) - menuBarSpacing
    return CGRect(x: trailing - appItemWidth, y: 0, width: appItemWidth, height: menuBarHeight)
  }

  static var menuFrame: CGRect {
    CGRect(
      x: appItem.minX, y: menuBarHeight + 2, width: menuWidth,
      height: Double(menuItems.count) * menuRowHeight + menuPadding * 2)
  }

  static func menuRowCenter(_ index: Int) -> CGPoint {
    CGPoint(
      x: menuFrame.minX + menuWidth / 2,
      y: menuFrame.minY + menuPadding + (Double(index) + 0.5) * menuRowHeight)
  }
}
