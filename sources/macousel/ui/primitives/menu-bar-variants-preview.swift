import SwiftUI

struct MenuBarVariantsPreview: View {
  let selection: MenuBarIndicator

  private var position: StripPosition {
    StripPosition(
      columnCount: PreviewMetrics.Sample.menuBarColumnCount,
      focusedIndex: PreviewMetrics.Sample.menuBarFocusedIndex, windowsInFocusedColumn: 1)
  }

  var body: some View {
    HStack(spacing: Metrics.Spacing.roomy) {
      ForEach(MenuBarIndicator.allCases, id: \.self) { indicator in
        variant(indicator)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Preview: menu bar shows \(selection.title.lowercased())")
  }

  private func variant(_ indicator: MenuBarIndicator) -> some View {
    let isSelected = indicator == selection
    return VStack(spacing: Metrics.Spacing.tight) {
      MenuBarLabelView(
        presentation: MenuBarPresentation(
          status: .running, position: position, indicator: indicator)
      )
      .frame(minWidth: PreviewMetrics.MenuBar.labelMinimumWidth)
      .padding(.horizontal, Metrics.Spacing.regular)
      .padding(.vertical, Metrics.Spacing.tight)
      .background(
        isSelected ? Color.accentColor.opacity(PreviewMetrics.MenuBar.selectedFill) : .clear,
        in: RoundedRectangle(cornerRadius: Metrics.Radius.chip, style: .continuous))
      Text(indicator.title)
        .font(.caption)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
    .opacity(isSelected ? 1 : PreviewMetrics.MenuBar.unselectedOpacity)
  }
}
