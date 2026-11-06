import SwiftUI

// A picker whose options are pictures. Each option is a button, so Tab and Space reach it and
// the system draws the focus ring. The selected picture gets an accent ring.
struct ChoiceTiles<Value: Hashable, Tile: View>: View {
  let title: String
  var detail: String?
  let options: [Value]
  @Binding var selection: Value
  let label: (Value) -> String
  @ViewBuilder let tile: (Value) -> Tile

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.regular) {
      VStack(alignment: .leading, spacing: Metrics.Spacing.hairline) {
        Text(title)
        if let detail {
          Text(detail)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      HStack(alignment: .top, spacing: Metrics.Spacing.comfortable) {
        ForEach(options, id: \.self, content: choice)
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(title)
  }

  private func choice(_ option: Value) -> some View {
    let isSelected = option == selection
    let shape = RoundedRectangle(cornerRadius: Metrics.Radius.tab, style: .continuous)
    return Button {
      selection = option
    } label: {
      VStack(spacing: Metrics.Spacing.compact) {
        tile(option)
          .frame(maxWidth: .infinity)
          .frame(height: SettingsMetrics.choiceTileHeight)
          .background(.fill.quaternary, in: shape)
          .clipShape(shape)
          .overlay {
            if isSelected {
              shape.strokeBorder(Color.accentColor, lineWidth: SettingsMetrics.choiceSelectedStroke)
            }
          }
        Text(label(option))
          .font(.subheadline)
          .foregroundStyle(isSelected ? .primary : .secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label(option))
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}
