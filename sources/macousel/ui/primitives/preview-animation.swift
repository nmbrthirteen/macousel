import SwiftUI

enum PreviewAnimation {
  static let durationPerResponse = 1.5

  static func curve(for speed: AnimationSpeed, reduceMotion: Bool) -> Animation? {
    guard !reduceMotion, let response = speed.springResponse else { return nil }
    return .easeOut(duration: response * durationPerResponse)
  }
}
