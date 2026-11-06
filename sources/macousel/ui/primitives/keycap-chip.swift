import SwiftUI
import WindowSystem

struct KeycapChip: View {
  let hotkey: Hotkey
  let removeLabel: String
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: Metrics.Spacing.tight) {
      Text(hotkey.displayString)
        .monospacedDigit()
      Button(removeLabel, systemImage: "xmark.circle.fill", action: onRemove)
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help(removeLabel)
    }
  }
}
