import SwiftUI

enum OverlayTextStyle {
  case small, regular, large

  var font: Font {
    switch self {
    case .small: .subheadline
    case .regular: .body
    case .large: .title3
    }
  }
}
