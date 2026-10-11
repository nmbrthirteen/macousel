import CoreGraphics

enum PreviewMetrics {
  static let sectionHeight = 150.0
  static let swipeSectionHeight = 196.0
  static let screenSize = CGSize(width: 1280, height: 800)
  static let horizontalInset = 12.0
  static let verticalInset = 10.0
  static let ghostOpacity = 1.0
  static let fadePlateau = 0.45
  static let windowCornerRadius = 3.0
  static let displayCornerRadius = 8.0
  static let unfocusedWindowOpacity = 0.14
  static let outlineOpacity = 0.35
  static let outlineWidth = 1.0
  static let borderWidthScale = 0.5
  static let borderedFocusFill = 0.28
  static let cardShadowOpacity = 0.25
  static let cardShadowRadius = 3.0
  static let cardTitleBarHeight = 0.16
  static let arrowWidth = 2.0
  static let arrowHeadSize = 5.0
  static let captionSpacing = 6.0

  enum Sample {
    static let focusTrailLength = 3
    static let layoutColumnCount = 6
    static let layoutRestingColumn = 1
    static let layoutAlternateColumn = 3
    static let motionColumnCount = 5
    static let motionColumnWidth = 0.5
    static let motionRestingColumn = 1
    static let motionAlternateColumn = 2
    static let rulesColumnCount = 4
    static let rulesColumnWidth = 0.4
    static let rulesFocusedColumn = 1
    static let motionLeadingColumns = 2
    static let rulesLeadingColumns = 3
    static let tiledColumnWidths = [0.4, 0.3, 0.3]
    static let tiledStackedColumn = 1
    static let tiledFocusedColumn = 0
    static let minimapColumnCount = 5
    static let minimapColumnWidth = 0.4
    static let menuBarColumnCount = 5
    static let menuBarFocusedIndex = 1
  }

  enum Timing {
    static let layoutInterval = Duration.seconds(2)
    static let motionInterval = Duration.milliseconds(800)
    static let swipeDebounce = Duration.milliseconds(350)
    static let swipeRestPause = Duration.milliseconds(150)
    static let swipeHold = Duration.milliseconds(1400)
    static let swipeDuration = 0.8
  }

  enum Swipe {
    static let columnCount = 10
    static let columnWidth = 1.0 / 3.0
    static let focusedColumn = 5
    static let startOffset = 1600.0
    static let padShare = 0.25
    static let travelPerPadWidth = 2.4
  }

  enum Trackpad {
    static let aspect = 1.4
    static let height = 64.0
    static let cornerRadius = 8.0
    static let fingerDiameter = 9.0
    static let fingerSpacing = 0.15
    static let fingerRestingY = 0.36
    static let fingerArcDepth = 0.05
    static let fingerTravel = 0.16
    static let arrowY = 0.74
    static let arrowReach = 0.26
    static let stripArrowHeight = 16.0
    static let stripArrowReach = 44.0
    static let rowSpacing = 6.0
  }

  enum Cards {
    static let rulesFloating = CGRect(x: 0.46, y: 0.28, width: 0.34, height: 0.5)
    static let looseOff = [
      CGRect(x: 0.12, y: 0.14, width: 0.46, height: 0.5),
      CGRect(x: 0.34, y: 0.3, width: 0.46, height: 0.5),
      CGRect(x: 0.5, y: 0.1, width: 0.38, height: 0.42),
    ]
  }

  enum Displays {
    static let labelHeight = 16.0
    static let gap = 3.0
    static let contentInset = 3.0
    static let horizontalInset = 16.0
    static let verticalInset = 10.0
    static let offOpacity = 0.5
    static let labelFontSize = 10.0
  }

  enum MenuBar {
    static let labelMinimumWidth = 36.0
    static let selectedFill = 0.18
    static let unselectedOpacity = 0.7
  }
}
