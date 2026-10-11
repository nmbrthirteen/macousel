import StripCore
import SwiftUI
import WindowSystem

struct DisplayDrawing: View {
  let displays: [Display]
  let disabled: Set<String>
  let config: LayoutConfig
  var animation: Animation?

  var body: some View {
    GeometryReader { proxy in
      let geometry = DisplayDrawingGeometry(
        displays: displays, disabled: disabled, container: proxy.size)
      ZStack(alignment: .topLeading) {
        ForEach(geometry.items) { item in
          DisplayScreenView(item: item, config: config, animation: animation)
        }
      }
    }
  }
}
