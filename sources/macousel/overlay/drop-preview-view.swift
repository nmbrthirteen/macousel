import SwiftUI

struct DropPreviewView: View {
  let model: DropPreviewModel

  var body: some View {
    PendingChangeView(radius: OverlayRadius.window)
      .frame(width: model.frame.width, height: model.frame.height)
      .offset(x: model.frame.minX, y: model.frame.minY)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .allowsHitTesting(false)
  }
}
