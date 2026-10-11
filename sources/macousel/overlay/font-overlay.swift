import SwiftUI

extension Font {
  static func overlay(_ style: OverlayTextStyle, weight: Font.Weight = .regular) -> Font {
    .system(size: style.size, weight: weight, design: .rounded).monospacedDigit()
  }
}
