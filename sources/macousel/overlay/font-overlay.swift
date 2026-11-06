import SwiftUI

extension Font {
  static func overlay(_ style: OverlayTextStyle, weight: Font.Weight = .regular) -> Font {
    style.font.weight(weight).monospacedDigit()
  }
}
