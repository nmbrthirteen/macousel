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
    .chipSurface()
  }
}
