import StripCore
import SwiftUI

struct CenterModePicker: View {
  @Binding var selection: CenterMode
  var detail: String?

  var body: some View {
    ChoiceTiles(
      title: "Center the focused column", detail: detail, options: CenterMode.allCases, selection: $selection,
      label: \.title
    ) { mode in
      MiniStripDiagram(strip: MiniStrip(centerMode: mode))
    }
  }
}
