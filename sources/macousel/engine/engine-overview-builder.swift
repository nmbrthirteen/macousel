import CoreGraphics

struct EngineOverviewBuilder {
  static let innerGap = 8.0

  let snapshot: EngineSnapshot
  let displayFrame: CGRect

  func build() -> OverviewSnapshot? {
    let windows = snapshot.tiledWindows
    let cells = windows.compactMap { window in
      EngineWindowID.make(window.windowId).map { (window, $0) }
    }
    guard !cells.isEmpty else { return nil }
    let width = displayFrame.width / 2
    let selection = snapshot.focusedColumnIndex.flatMap { index in
      windows.indices.contains(index) ? EngineWindowID.make(windows[index].windowId) : nil
    }
    return OverviewSnapshot(
      columns: cells.map { window, id in
        OverviewSnapshot.Column(
          width: width,
          cards: [
            OverviewSnapshot.Card(
              window: id, title: window.title.isEmpty ? window.appName : window.title,
              bundleIdentifier: window.bundleId, heightShare: 1)
          ])
      },
      stripHeight: displayFrame.height - 2 * Self.innerGap, selection: selection,
      usableWidth: displayFrame.width, innerGap: Self.innerGap)
  }
}
