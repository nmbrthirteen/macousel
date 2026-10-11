import StripCore
import SwiftUI

struct MinimapPreview: View {
  let config: LayoutConfig
  let isEnabled: Bool
  @State private var model = MinimapModel()

  private var snapshot: MinimapSnapshot {
    MinimapSampleSnapshot.make(config: config)
  }

  var body: some View {
    let width = MinimapGeometry(snapshot: snapshot).containerWidth
    MinimapView(model: model)
      .frame(width: width, height: Metrics.Minimap.height, alignment: .topLeading)
      .background(
        Color(nsColor: .windowBackgroundColor),
        in: RoundedRectangle(cornerRadius: Metrics.Minimap.containerRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: Metrics.Minimap.containerRadius, style: .continuous)
          .strokeBorder(
            Color.primary.opacity(PreviewMetrics.outlineOpacity),
            lineWidth: Metrics.Size.hairlineStroke)
      }
      .opacity(isEnabled ? 1 : SettingsMetrics.disabledPreviewOpacity)
      .frame(maxWidth: .infinity, alignment: .center)
      .onAppear(perform: refresh)
      .onChange(of: config) { refresh() }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Preview: strip minimap")
  }

  private func refresh() {
    model.isShown = true
    model.apply(snapshot, update: .immediate)
  }
}
