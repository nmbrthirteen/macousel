import SwiftUI

struct DropPreviewView: View {
  let model: DropPreviewModel

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Metrics.DropPreview.cornerRadius, style: .continuous)
  }

  var body: some View {
    shape
      .fill(Color.accentColor.opacity(Metrics.Opacity.dropPreviewFill))
      .overlay {
        shape.strokeBorder(
          Color.accentColor.opacity(Metrics.Opacity.dropPreviewBorder),
          lineWidth: Metrics.DropPreview.borderWidth)
      }
      .frame(width: model.frame.width, height: model.frame.height)
      .offset(x: model.frame.minX, y: model.frame.minY)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .allowsHitTesting(false)
  }
}
