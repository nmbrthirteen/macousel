import Foundation

enum OverlayTiming {
  static let fade: TimeInterval = 0.12
  static let dropPreviewFade: TimeInterval = 0.1
  static let dropPreviewResponse = 0.22
  static let minimapAppear: TimeInterval = 0.12
  static let minimapDisappear: TimeInterval = 0.2
  static let minimapFocusResponse = 0.25
  static let minimapHiddenScale = 0.98
  static let minimapLinger = Duration.milliseconds(900)
  static let springDamping = 0.85
  static let criticalDamping = 1.0
  static let liftScale = 1.03
  static let minimapLiftScale = 1.08
  static let overviewOpenResponse = 0.35
  static let overviewCloseResponse = 0.3
  static let overviewPreviewFade: TimeInterval = 0.2
  static let overviewHoverScale = 1.02
  static let overviewSelectedScale = 1.015
  static let overviewHoverResponse = 0.2
}
