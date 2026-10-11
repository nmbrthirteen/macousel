import CoreGraphics
import StripCore

@testable import Macousel

@MainActor
enum OverviewSnapshots {
  static let size = CGSize(width: 1000, height: 800)

  static func make(
    columns: [[UInt32]], width: Double = 300, tabbed: Set<Int> = [], selection: UInt32? = nil
  ) -> OverviewSnapshot {
    let built = columns.enumerated().map { index, windows in
      OverviewSnapshot.Column(
        width: width,
        cards: windows.map {
          OverviewSnapshot.Card(
            window: WindowID($0), title: "Window \($0)", bundleIdentifier: nil,
            heightShare: 1 / Double(windows.count))
        }, isTabbed: tabbed.contains(index))
    }
    return OverviewSnapshot(
      columns: built, stripHeight: 768, selection: selection.map { WindowID($0) },
      usableWidth: 984, innerGap: 8, presetWidths: [0.25, 0.5, 0.75])
  }

  static func windows(_ snapshot: OverviewSnapshot) -> [[UInt32]] {
    snapshot.columns.map { $0.cards.map(\.window.rawValue) }
  }
}
