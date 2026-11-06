import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct MinimapViewportTests {
  @Test func tileWidthsFollowTheColumnWidths() {
    var wide = MinimapSnapshots.strip(
      columns: 3,
      replacing: [
        1: MinimapSnapshot.Column(
          x: 500, width: 992, rows: [MinimapSnapshots.row(2)], activeRow: 0, isTabbed: false,
          isFocused: false)
      ])
    wide.columns[2].x = 1500
    wide.contentWidth = 1992
    let cells = MinimapGeometry(snapshot: wide).cells
    let gap = Metrics.Minimap.columnGap
    let ratio = (cells[1].rect.width + gap) / (cells[0].rect.width + gap)
    #expect(abs(ratio - 992.0 / 492) < 0.1)
  }

  @Test func theStaticContainerWidthMatchesTheGeometry() {
    for columns in [1, 4, 12, 40] {
      let snapshot = MinimapSnapshots.strip(columns: columns)
      #expect(
        MinimapGeometry.containerWidth(for: snapshot)
          == MinimapGeometry(snapshot: snapshot).containerWidth)
    }
  }

  @Test func columnsInsideTheViewportAreOnScreenAndTheRestDimmed() {
    let cells = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4)).cells
    #expect(cells.map(\.isOnScreen) == [true, true, false, false])
  }

  @Test func aSliverPeekingAtTheEdgeIsDimmed() {
    let snapshot = MinimapSnapshots.strip(columns: 4, viewportOffset: 400)
    let cells = MinimapGeometry(snapshot: snapshot).cells
    #expect(cells.map(\.isOnScreen) == [false, true, true, false])
  }

  @Test func aColumnWiderThanTheScreenCountsAsOnScreen() {
    let snapshot = MinimapSnapshots.strip(
      columns: 2, columnWidth: 2400, pitch: 2408, viewportOffset: 500)
    let cells = MinimapGeometry(snapshot: snapshot).cells
    #expect(cells.map(\.isOnScreen) == [true, false])
  }

  @Test func theLensCoversExactlyTheTilesThatAreOnScreen() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4))
    for cell in geometry.cells {
      let center = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
      #expect(geometry.lens.contains(center) == cell.isOnScreen)
    }
  }

  @Test func theFocusRingWrapsTheFocusedTile() throws {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4, focused: 2))
    let ring = try #require(geometry.focusRing)
    let cell = geometry.cells[2]
    let outset = Metrics.Minimap.focusRingOutset
    #expect(ring.cell == cell.id)
    #expect(ring.rect == cell.rect.insetBy(dx: -outset, dy: -outset))
    #expect(abs(ring.cornerRadius - (cell.cornerRadius + outset)) < 0.001)
  }

  @Test func theFocusRingStaysClearOfTheNeighbouringTiles() throws {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4, focused: 1))
    let ring = try #require(geometry.focusRing)
    #expect(ring.rect.minX > geometry.cells[0].rect.maxX)
    #expect(ring.rect.maxX < geometry.cells[2].rect.minX)
  }

  @Test func inAStackOnlyTheFocusedWindowCarriesTheRing() throws {
    let stacked = MinimapSnapshot.Column(
      x: 0, width: 492, rows: [MinimapSnapshots.row(1), MinimapSnapshots.row(5)], activeRow: 1,
      isTabbed: false, isFocused: true)
    let snapshot = MinimapSnapshots.strip(columns: 3, replacing: [0: stacked])
    let geometry = MinimapGeometry(snapshot: snapshot)
    #expect(geometry.cells.filter(\.isFocused).map(\.window) == [WindowID(5)])
    #expect(try #require(geometry.focusRing).cell == WindowID(5))
  }

  @Test func noFocusedColumnDrawsNoRing() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 3, focused: -1))
    #expect(geometry.focusRing == nil)
  }

  @Test func thePanelHoldsTheStripAndTheLabel() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4))
    #expect(geometry.panelBounds.height > geometry.bounds.height)
    #expect(
      Metrics.Minimap.panelHeight
        == Metrics.Minimap.height + Metrics.Minimap.labelLineHeight
        + Metrics.Minimap.verticalPadding)
  }

  @Test func theLabelNamesTheAppOfTheFocusedWindow() {
    let snapshot = MinimapSnapshots.strip(columns: 3, focused: 1)
    let text = MinimapLabel.text(for: snapshot.focusedWindow, in: snapshot) { "Name of \($0)" }
    #expect(text == "Name of com.example.app")
  }

  @Test func aWindowWithoutABundleFallsBackToItsColumn() {
    let column = MinimapSnapshot.Column(
      x: 1000, width: 492, rows: [MinimapSnapshots.row(3, app: nil)], activeRow: 0,
      isTabbed: false, isFocused: true)
    let snapshot = MinimapSnapshots.strip(columns: 3, focused: 2, replacing: [2: column])
    #expect(MinimapLabel.text(for: WindowID(3), in: snapshot) { $0 } == "Column 3")
    #expect(MinimapLabel.text(for: WindowID(9), in: snapshot) { $0 } == nil)
    #expect(MinimapLabel.text(for: nil, in: snapshot) { $0 } == nil)
  }
}
