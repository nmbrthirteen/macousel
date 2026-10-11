import StripCore

@testable import Macousel

@MainActor
enum MinimapSnapshots {
  static func row(_ window: UInt32, height: Double = 700, app: String? = "com.example.app")
    -> MinimapSnapshot.Row
  {
    MinimapSnapshot.Row(window: WindowID(window), bundleIdentifier: app, height: height)
  }

  static func strip(
    columns: Int, columnWidth: Double = 492, pitch: Double = 500, focused: Int = 0,
    viewportOffset: Double = 0, viewportWidth: Double = 1000,
    replacing custom: [Int: MinimapSnapshot.Column] = [:]
  ) -> MinimapSnapshot {
    MinimapSnapshot(
      columns: (0..<columns).map { index in
        custom[index]
          ?? MinimapSnapshot.Column(
            x: Double(index) * pitch, width: columnWidth, rows: [row(UInt32(index + 1))],
            activeRow: 0, isTabbed: false, isFocused: index == focused)
      },
      contentWidth: Double(columns) * pitch - (pitch - columnWidth),
      viewportOffset: viewportOffset, viewportWidth: viewportWidth, animationResponse: 0.3)
  }
}
