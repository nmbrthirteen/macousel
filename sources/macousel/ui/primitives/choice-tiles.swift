import SwiftUI

struct ChoiceTiles<Value: Hashable, Tile: View>: View {
  let title: String
  let options: [Value]
  @Binding var selection: Value
  let label: (Value) -> String
  @ViewBuilder let tile: (Value) -> Tile

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.regular) {
      Text(title)
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
            shape.strokeBorder(
              isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.separator),
              lineWidth: isSelected ? SettingsMetrics.choiceSelectedStroke : Metrics.Size.hairlineStroke)
          }
        Text(label(option))
          .font(.caption)
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
