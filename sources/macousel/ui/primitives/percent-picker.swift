import SwiftUI

struct PercentPicker: View {
  static let standardOptions = [0.25, 1.0 / 3.0, 0.5, 2.0 / 3.0, 0.75, 1.0]

  let title: String
  @Binding var selection: Double
  var options = standardOptions

  var body: some View {
    Picker(title, selection: nearestOption) {
      ForEach(options, id: \.self) { option in
        Text("\(option.wholePercent)%").tag(option)
      }
    }
  }

  private var nearestOption: Binding<Double> {
    Binding(
      get: { options.min { abs($0 - selection) < abs($1 - selection) } ?? selection },
      set: { selection = $0 }
    )
  }
}
