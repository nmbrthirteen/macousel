import CoreGraphics

struct EngineOverviewBuilder {
  static let innerGap = 8.0

  let snapshot: EngineSnapshot
  let displayFrame: CGRect

  func build() -> OverviewSnapshot? {
    let columns = snapshot.tiledColumns.columns.map(column(from:)).filter { !$0.cards.isEmpty }
    guard !columns.isEmpty else { return nil }
    return OverviewSnapshot(
      columns: columns, stripHeight: displayFrame.height - 2 * Self.innerGap,
      selection: snapshot.focusedWindowID, usableWidth: displayFrame.width,
      innerGap: Self.innerGap, springResponse: OverlayTiming.overviewOpenResponse,
      allowsResize: false,
      floating: snapshot.floatingWindows.compactMap { card(from: $0, share: 1) })
  }

  private func card(from window: EngineWindow, share: Double) -> OverviewSnapshot.Card? {
    EngineWindowID.make(window.windowId).map { id in
      OverviewSnapshot.Card(
        window: id, title: window.title.isEmpty ? window.appName : window.title,
        bundleIdentifier: window.bundleId, heightShare: share, frame: window.frame?.rect)
    }
  }

  private func column(from column: EngineColumns.Column) -> OverviewSnapshot.Column {
    let cards = zip(column.windows, column.heightShares).compactMap(card(from:share:))
    return OverviewSnapshot.Column(width: column.width ?? displayFrame.width / 2, cards: cards)
  }
}
