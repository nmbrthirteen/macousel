import SwiftUI

enum MinimapUpdate: Equatable {
  case animated
  case immediate

  func animation(response: Double?) -> Animation? {
    guard self == .animated, let response else { return nil }
    return .spring(response: response, dampingFraction: OverlayTiming.criticalDamping)
  }
}
