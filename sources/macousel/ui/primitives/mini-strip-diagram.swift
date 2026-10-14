import SwiftUI

struct MiniStripDiagram: View {
  let strip: MiniStrip

  var body: some View {
    GeometryReader { proxy in
      let height = proxy.size.height - SettingsMetrics.diagramInset * 2
      ForEach(strip.columns.indices, id: \.self) { index in
        let column = strip.columns[index]
        RoundedRectangle(cornerRadius: SettingsMetrics.diagramRadius, style: .continuous)
          .fill(
            column.isFocused
              ? Color.accentColor : Color.primary.opacity(PreviewMetrics.unfocusedWindowOpacity))
          .frame(
            width: max(column.width * proxy.size.width - SettingsMetrics.diagramGap, 0),
            height: height)
          .offset(
            x: column.x * proxy.size.width + SettingsMetrics.diagramGap / 2,
            y: SettingsMetrics.diagramInset)
      }
    }
  }
}
