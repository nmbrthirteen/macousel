import SwiftUI

struct RemovableChip: View {
  let title: String
  let removeLabel: String
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: Metrics.Spacing.tight) {
      Text(title)
        .monospacedDigit()
      Button(removeLabel, systemImage: "xmark.circle.fill", action: onRemove)
        .labelStyle(.iconOnly)
        .foregroundStyle(.secondary)
        .buttonStyle(.borderless)
        .help(removeLabel)
    }
    .chipSurface()
  }
}
