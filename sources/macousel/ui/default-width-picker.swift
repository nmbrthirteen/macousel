import SwiftUI

struct DefaultWidthPicker: View {
  @Binding var selection: Double
  var detail: String?

  var body: some View {
    ChoiceTiles(
      title: "Default width of new windows", detail: detail, options: PercentPicker.standardOptions,
      selection: PercentPicker.nearest(in: PercentPicker.standardOptions, to: $selection),
      label: { "\($0.wholePercent)%" }
    ) { width in
      MiniStripDiagram(strip: MiniStrip(defaultWidth: width))
    }
  }
}
