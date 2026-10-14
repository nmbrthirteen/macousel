import StripCore
import SwiftUI

struct CenterModePicker: View {
  @Binding var selection: CenterMode

  var body: some View {
    ChoiceTiles(
      title: "Center the focused column", options: CenterMode.allCases, selection: $selection,
      label: \.title
    ) { mode in
      MiniStripDiagram(strip: MiniStrip(centerMode: mode))
    }
  }
}
