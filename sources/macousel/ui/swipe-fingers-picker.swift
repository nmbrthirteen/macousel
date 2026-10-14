import SwiftUI

struct SwipeFingersPicker: View {
  static let options = [3, 4]

  @Binding var selection: Int
  let reversesDirection: Bool

  var body: some View {
    ChoiceTiles(
      title: "Swipe fingers", options: Self.options, selection: $selection,
      label: { "\($0) fingers" }
    ) { count in
      TrackpadDiagram(
        diagram: SwipeDiagram(fingerCount: count, reversesDirection: reversesDirection), progress: 0)
        .scaleEffect(SettingsMetrics.trackpadScale)
    }
  }
}
