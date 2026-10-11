import StripCore
import SwiftUI

struct DisplayScreenView: View {
  let item: DisplayDrawingGeometry.Item
  let config: LayoutConfig
  var animation: Animation?

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: PreviewMetrics.displayCornerRadius, style: .continuous)
  }

  private var outline: CGRect {
    item.screenRect.insetBy(dx: PreviewMetrics.Displays.gap / 2, dy: PreviewMetrics.Displays.gap / 2)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      shape
        .fill(Color(nsColor: .windowBackgroundColor))
        .overlay {
          shape.strokeBorder(
            Color.primary.opacity(PreviewMetrics.outlineOpacity),
            lineWidth: PreviewMetrics.outlineWidth)
        }
        .frame(width: outline.width, height: outline.height)
        .offset(x: outline.minX - item.screenRect.minX, y: outline.minY - item.screenRect.minY)
      content
        .frame(width: item.contentRect.width, height: item.contentRect.height)
        .offset(x: item.contentRect.minX - item.screenRect.minX, y: item.contentRect.minY - item.screenRect.minY)
      Text(item.name)
        .font(.system(size: PreviewMetrics.Displays.labelFontSize))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(width: item.labelRect.width, height: item.labelRect.height)
        .offset(x: item.labelRect.minX - item.screenRect.minX, y: item.labelRect.minY - item.screenRect.minY)
    }
    .frame(width: item.screenRect.width, height: item.screenRect.height, alignment: .topLeading)
    .offset(x: item.screenRect.minX, y: item.screenRect.minY)
  }

  @ViewBuilder
  private var content: some View {
    if item.isTiled {
      StripPreview(
        scenario: PreviewScenarios.tiledDisplay(), config: config, animation: animation,
        style: .embedded, screenSize: contentScreenSize)
    } else {
      LooseCardsView()
    }
  }

  private var contentScreenSize: CGSize {
    let width = PreviewMetrics.screenSize.width
    return CGSize(width: width, height: width * item.contentRect.height / max(item.contentRect.width, 1))
  }
}
