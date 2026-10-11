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
    static let focusBorder = 16.0
    static let panel = 12.0
    static let column = 2.0
    static let viewport = 3.0
    static let illustrationColumn = 4.0
  }

  enum Opacity {
    static let activeTab = 0.35
    static let overviewBackdrop = 0.45
    static let overviewBadge = 0.18
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
    static let onboardingWidth = 480.0
    static let onboardingHeight = 420.0
    static let illustrationHeight = 120.0
    static let statusIcon = 20.0
    static let hairlineStroke = 0.5
    static let outlineStroke = 1.0
    static let illustrationStroke = 2.0
  }
}
