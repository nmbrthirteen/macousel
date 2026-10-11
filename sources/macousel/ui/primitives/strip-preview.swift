import StripCore
import SwiftUI

struct StripPreview: View {
  let scenario: StripPreviewScenario
  let config: LayoutConfig
  var decoration = StripPreviewDecoration.none
  var animation: Animation?
  var style = StripPreviewStyle.standalone
  var screenSize = PreviewMetrics.screenSize

  private var displayShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: PreviewMetrics.displayCornerRadius, style: .continuous)
  }

  var body: some View {
    GeometryReader { proxy in
      let geometry = StripPreviewGeometry(
        scenario: scenario, config: config, container: proxy.size, screenSize: screenSize,
        showsOverflow: style == .standalone)
      ZStack(alignment: .topLeading) {
        if style == .standalone {
          overflow(geometry)
        }
        display(geometry)
      }
      .animation(animation, value: geometry.windows)
    }
  }

  private func overflow(_ geometry: StripPreviewGeometry) -> some View {
    StripPreviewLayer(geometry: geometry, decoration: .none)
      .opacity(PreviewMetrics.ghostOpacity)
      .mask(alignment: .topLeading) {
        HStack(spacing: 0) {
          LinearGradient(
            stops: [
              .init(color: .clear, location: 0),
              .init(color: .black, location: 1 - PreviewMetrics.fadePlateau),
            ], startPoint: .leading, endPoint: .trailing
          )
          .frame(width: geometry.leadingFade.width)
          Color.clear.frame(width: geometry.displayRect.width)
          LinearGradient(
            stops: [
              .init(color: .black, location: PreviewMetrics.fadePlateau),
              .init(color: .clear, location: 1),
            ], startPoint: .leading, endPoint: .trailing
          )
          .frame(width: geometry.trailingFade.width)
        }
        .frame(width: geometry.container.width, height: geometry.container.height)
      }
  }

  private func display(_ geometry: StripPreviewGeometry) -> some View {
    let rect = geometry.displayRect
    return ZStack(alignment: .topLeading) {
      if style == .standalone {
        displayShape
          .fill(Color(nsColor: .windowBackgroundColor))
          .frame(width: rect.width, height: rect.height)
          .offset(x: rect.minX, y: rect.minY)
      }
      StripPreviewLayer(geometry: geometry, decoration: decoration)
        .mask(alignment: .topLeading) {
          displayShape
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
        }
      if style == .standalone {
        displayShape
          .strokeBorder(
            Color.primary.opacity(PreviewMetrics.outlineOpacity),
            lineWidth: PreviewMetrics.outlineWidth)
          .frame(width: rect.width, height: rect.height)
          .offset(x: rect.minX, y: rect.minY)
      }
    }
  }
}
