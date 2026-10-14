import SwiftUI

struct MenuBarIndicatorPicker: View {
  private static let widthShares = [0.4, 0.3, 0.5, 0.3, 0.4]
  private static let stackedIndex = 3

  @Binding var selection: MenuBarIndicator

  private var position: StripPosition {
    StripPosition(
      pages: (0..<PreviewMetrics.Sample.menuBarColumnCount).map {
        StripPosition.Page(
          widthShare: Self.widthShares[$0 % Self.widthShares.count],
          rowCount: $0 == Self.stackedIndex ? 2 : 1)
      },
      focusedIndex: PreviewMetrics.Sample.menuBarFocusedIndex)
  }

  var body: some View {
    ChoiceTiles(
      title: "Menu bar shows", options: MenuBarIndicator.allCases, selection: $selection,
      label: \.title
    ) { indicator in
      MenuBarLabelView(
        presentation: MenuBarPresentation(status: .running, position: position, indicator: indicator))
    }
  }
}
