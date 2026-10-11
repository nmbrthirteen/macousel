import SwiftUI

struct PresetWidthsEditor: View {
  private static let allowedPercents = 10...100
  private static let percentStep = 5
  private static let initialPercent = 50

  @Binding var widths: [Double]
  @Binding var hoveredWidth: Double?
  @State private var newPercent = initialPercent

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.regular) {
      Text("Preset widths")
      FlowLayout(spacing: Metrics.Spacing.compact) {
        ForEach(widths, id: \.self) { width in
          RemovableChip(title: "\(width.wholePercent)%") {
            widths.removeAll { $0 == width }
          }
          .disabled(widths.count <= 1)
          .onHover { isInside in
            if isInside {
              hoveredWidth = width
            } else if hoveredWidth == width {
              hoveredWidth = nil
            }
          }
          .onDisappear {
            if hoveredWidth == width { hoveredWidth = nil }
          }
        }
      }
      HStack {
        Text("\(newPercent)%")
          .monospacedDigit()
        Stepper("New width", value: $newPercent, in: Self.allowedPercents, step: Self.percentStep)
          .labelsHidden()
        Button("Add", action: add)
          .disabled(widths.contains { $0.wholePercent == newPercent })
        Spacer()
      }
    }
  }

  private func add() {
    var seen = Set<Int>()
    widths = (widths + [Double(newPercent) / 100])
      .filter { Self.allowedPercents.contains($0.wholePercent) && seen.insert($0.wholePercent).inserted }
      .sorted()
  }
}
