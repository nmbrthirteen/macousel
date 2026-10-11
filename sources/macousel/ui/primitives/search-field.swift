import SwiftUI

struct SearchField: View {
  let label: String
  @Binding var text: String

  var body: some View {
    HStack(spacing: SettingsMetrics.filterSpacing) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      TextField(label, text: $text)
        .textFieldStyle(.plain)
      if !text.isEmpty {
        Button("Clear \(label.lowercased())", systemImage: "xmark.circle.fill") { text = "" }
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          .foregroundStyle(.secondary)
      }
    }
  }
}
