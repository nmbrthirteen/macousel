import SwiftUI

struct FocusBorderView: View {
  let model: FocusBorderModel

  var body: some View {
    RoundedRectangle(cornerRadius: OverlayRadius.window + model.lineWidth, style: .continuous)
      .strokeBorder(Color.accentColor, lineWidth: model.lineWidth)
  }
}
