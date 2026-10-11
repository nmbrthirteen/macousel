import Foundation

enum OverlayTiming {
  static let fade: TimeInterval = 0.12
  static let dropPreviewFade: TimeInterval = 0.1
  static let dropPreviewResponse = 0.22
  static let slowFade: TimeInterval = 0.25
  static let minimapAppear: TimeInterval = 0.14
  static let minimapLinger = Duration.milliseconds(900)
  static let springDamping = 0.85
  static let criticalDamping = 1.0
  static let hiddenScale = 0.96
  static let liftScale = 1.03
  static let minimapLiftScale = 1.08
}
