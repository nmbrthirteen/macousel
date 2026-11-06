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
    PreviewCard(description: "Preview: strip minimap", height: PreviewMetrics.minimapCardHeight) {
      MinimapView(model: model)
        .frame(width: width, height: Metrics.Minimap.panelHeight, alignment: .topLeading)
        .background(
          Color(nsColor: .windowBackgroundColor),
          in: RoundedRectangle(cornerRadius: Metrics.Minimap.containerRadius, style: .continuous)
        )
        .opacity(isEnabled ? 1 : SettingsMetrics.disabledPreviewOpacity)
    }
    .onAppear(perform: refresh)
    .onChange(of: config) { refresh() }
  }

  private func refresh() {
    model.isShown = true
    model.apply(snapshot, update: .immediate)
  }
}
