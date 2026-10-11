import SwiftUI

struct TabBarView: View {
  let content: TabBarContent

  var body: some View {
    HStack(spacing: Metrics.Spacing.hairline) {
      ForEach(content.tabs) { tab in
        Text(tab.title)
          .font(.overlay(.regular))
          .lineLimit(1)
          .truncationMode(.middle)
          .foregroundStyle(tab.isActive ? Color.white : Color.secondary)
          .padding(.horizontal, Metrics.Spacing.regular)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(tab.isActive ? Color.accentColor : .clear, in: Capsule())
          .contentShape(Rectangle())
          .onTapGesture { content.onSelect(tab.id) }
          .accessibilityAddTraits(tab.isActive ? [.isButton, .isSelected] : .isButton)
      }
    }
    .padding(Metrics.Spacing.hairline)
    .overlaySurface(in: Capsule())
  }
}
