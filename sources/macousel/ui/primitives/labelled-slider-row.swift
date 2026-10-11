import SwiftUI

struct LabelledSliderRow: View {
  let title: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let readout: SliderReadout

  var body: some View {
    LabeledContent(title) {
      HStack {
        Slider(value: $value, in: range, step: step)
          .frame(width: Metrics.Size.sliderWidth)
          .labelsHidden()
        Text(readout.text(for: value))
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .frame(width: Metrics.Size.sliderReadoutWidth, alignment: .trailing)
      }
    }
  }
}
