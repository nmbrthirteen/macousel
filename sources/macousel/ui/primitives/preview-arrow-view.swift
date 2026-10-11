import StripCore
import SwiftUI

struct PreviewArrowView: View {
  let direction: StripCore.HorizontalDirection

  var body: some View {
    PreviewArrow(direction: direction, headSize: PreviewMetrics.arrowHeadSize)
      .stroke(
        Color.secondary,
        style: StrokeStyle(lineWidth: PreviewMetrics.arrowWidth, lineCap: .round, lineJoin: .round))
  }
}
