import SwiftUI

struct LabelledSliderRow: View {
  let title: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let readout: SliderReadout

  // A stepped slider draws a tick mark per step, so the slider stays continuous and the
  // binding snaps instead.
  private var snapped: Binding<Double> {
    Binding(
      get: { value },
      set: { value = min(max(($0 / step).rounded() * step, range.lowerBound), range.upperBound) })
  }

  var body: some View {
    Slider(value: snapped, in: range) {
      RowLabel(title: title, detail: readout.text(for: value))
    }
    .accessibilityValue(readout.text(for: value))
    .help(readout.text(for: value))
  }
}
