import SwiftUI

struct RemovableChip: View {
  let title: String
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: Metrics.Spacing.tight) {
      Text(title)
        .monospacedDigit()
      Button("Remove \(title)", systemImage: "xmark.circle.fill", action: onRemove)
        .labelStyle(.iconOnly)
        .foregroundStyle(.secondary)
        .buttonStyle(.borderless)
    }
    .padding(.horizontal, Metrics.Spacing.regular)
    .padding(.vertical, Metrics.Spacing.tight)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: Metrics.Radius.chip))
  }
}
