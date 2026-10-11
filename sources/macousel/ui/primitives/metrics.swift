import CoreGraphics

enum Metrics {
  enum Spacing {
    static let hairline = 2.0
    static let tight = 4.0
    static let compact = 6.0
    static let regular = 8.0
    static let comfortable = 12.0
    static let roomy = 16.0
    static let spacious = 24.0
  }

  enum Radius {
    static let chip = 6.0
    static let sidebarTile = 6.0
    static let tab = 8.0
    static let window = 16.0
    static let concentricFloor = 4.0
    static let panel = 12.0
  }

  enum Opacity {
    static let overviewBackdrop = 0.45
    static let overviewBadge = 0.18
    static let minimapColumn = 0.22
    static let minimapLens = 0.10
    static let minimapLensBorder = 0.30
    static let minimapTabDot = 0.5
    static let minimapNumber = 0.85
    static let pendingFill = 0.22
    static let pendingBorder = 0.70
  }

  enum Overlay {
    static let pendingBorderWidth = 1.0
    static let dragThreshold = 4.0
    static let liftShadowOpacity = 0.35
    static let smallText = 11.0
    static let regularText = 13.0
    static let largeText = 15.0
  }

  enum Minimap {
    static let height = 40.0
    static let minimumWidth = 140.0
    static let maximumWidth = 360.0
    static let horizontalPadding = 14.0
    static let verticalPadding = 7.0
    static let stripScale = 0.1
    static let columnGap = 3.0
    static let rowGap = 2.0
    static let containerRadius = Radius.window - Spacing.hairline
    static let stackedRowRadiusShare = 1.0 / 3.0
    static let lensOutset = 3.0
    static let iconSide = 14.0
    static let iconMinimumWidth = 26.0
    static let iconMinimumHeight = 18.0
    static let numberMinimumWidth = 12.0
    static let numberMinimumHeight = 10.0
    static let highestNumberedColumn = 9
    static let pairMinimumWidth = 34.0
    static let pairGap = 3.0
    static let numberSlotWidth = 7.0
    static let tabDotDiameter = 3.0
    static let tabDotGap = 2.0
    static let tabDotInset = 2.0
    static let tabDotLimit = 3
    static let liftShadowRadius = 5.0
  }

  enum Overview {
    static let maximumScale = 0.5
    static let edgeMargin = 32.0
    static let columnGap = 12.0
    static let stackGap = 6.0
    static let iconSide = 48.0
    static let compactIconSide = 16.0
    static let selectionStroke = 3.0
    static let roomyCardMinimumHeight = 110.0
    static let titleMinimumWidth = 72.0
    static let badgeMinimumWidth = 22.0
    static let titleLineLimit = 2
    static let liftShadowRadius = 16.0
    static let liftOpacity = 0.9
    static let edgeHitWidth = 12.0
    static let dividerHitHeight = 12.0
    static let presetSnapRange = 0.03
    static let labelOffset = 8.0
    static let lastPlace = 9
    static let widthNoise = 0.5
    static let labelHeight = 24.0
    static let gripThickness = 3.0
    static let gripLength = 28.0
    static let gripOpacity = 0.4
    static let gripHoverOpacity = 0.8
  }

  enum Size {
    static let sliderWidth = 180.0
    static let sliderReadoutWidth = 48.0
    static let appIcon = 16.0
    static let settingsWidth = 780.0
    static let settingsHeight = 560.0
    static let settingsMinWidth = 660.0
    static let settingsMinHeight = 420.0
    static let sidebarMinWidth = 200.0
    static let sidebarIdealWidth = 220.0
    static let sidebarMaxWidth = 280.0
    static let sidebarTile = 24.0
    static let sidebarGlyph = 13.0
    static let aboutIcon = 96.0
    static let statusIcon = 20.0
    static let hairlineStroke = 0.5
  }
}
