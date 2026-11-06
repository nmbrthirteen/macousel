import SwiftUI

struct PresetWidthsEditor: View {
  private static let allowedPercents = 10...100
  private static let percentStep = 5
  private static let initialPercent = 50

  @Binding var widths: [Double]
  @Binding var hoveredWidth: Double?
  @State private var newPercent = initialPercent

  var body: some View {
    ForEach(widths, id: \.self) { width in
      LabeledContent("\(width.wholePercent)%") {
        RemoveButton(label: "Remove \(width.wholePercent)% preset") {
          widths.removeAll { $0 == width }
        }
        .disabled(widths.count <= 1)
      }
      .monospacedDigit()
      .contentShape(Rectangle())
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
    LabeledContent("Add a preset") {
      HStack(spacing: Metrics.Spacing.regular) {
        Text("\(newPercent)%")
          .monospacedDigit()
        Stepper("New preset width", value: $newPercent, in: Self.allowedPercents, step: Self.percentStep)
          .labelsHidden()
        Button("Add", action: add)
          .disabled(widths.contains { $0.wholePercent == newPercent })
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
