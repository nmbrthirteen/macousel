import SwiftUI

enum PreviewAnimation {
  static func spring(for speed: AnimationSpeed, reduceMotion: Bool) -> Animation? {
    guard !reduceMotion, let response = speed.springResponse else { return nil }
    return .spring(response: response, dampingFraction: 1)
  }
}
