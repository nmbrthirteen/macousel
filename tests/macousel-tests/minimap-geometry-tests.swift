import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct MinimapGeometryTests {
  private func stacked(heights: [Double]) -> MinimapSnapshot.Column {
    MinimapSnapshot.Column(
      x: 0, width: 492,
      rows: heights.enumerated().map { MinimapSnapshots.row(UInt32($0.offset + 1), height: $0.element) },
      activeRow: 0, isTabbed: false, isFocused: true)
  }

  private func tabbed(windows: UInt32, active: Int) -> MinimapSnapshot.Column {
    MinimapSnapshot.Column(
      x: 0, width: 492,
      rows: (1...windows).map { MinimapSnapshots.row($0, app: "app.\($0)") },
      activeRow: active, isTabbed: true, isFocused: true)
  }

  @Test(arguments: [(1000.0, 140.0), (2000.0, 228.0), (3000.0, 328.0), (20000.0, 360.0)])
  func capsuleWidthFollowsTheContentWithinBounds(content: Double, expected: Double) {
    var snapshot = MinimapSnapshots.strip(columns: 2)
    snapshot.contentWidth = content
    let geometry = MinimapGeometry(snapshot: snapshot)
    #expect(abs(geometry.capsuleWidth - expected) < 0.001)
    #expect(geometry.capsuleWidth >= Metrics.Minimap.minimumWidth)
    #expect(geometry.capsuleWidth <= Metrics.Minimap.maximumWidth)
  }

  @Test func lensCoversTheViewportShare() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4))
    #expect(abs(geometry.lens.minX - 11) < 0.001)
    #expect(abs(geometry.lens.width - 106) < 0.001)
    #expect(abs(geometry.lens.minY - 4) < 0.001)
    #expect(abs(geometry.lens.height - 32) < 0.001)
  }

  @Test func lensSlidesWithTheViewportOffset() {
    let geometry = MinimapGeometry(
      snapshot: MinimapSnapshots.strip(columns: 4, viewportOffset: 500))
    #expect(abs(geometry.lens.minX - 61) < 0.001)
  }

  @Test func lensStaysInsideTheCapsuleWhenTheViewportIsInsideTheContent() {
    for offset in [0.0, 400, 992] {
      let geometry = MinimapGeometry(
        snapshot: MinimapSnapshots.strip(columns: 4, viewportOffset: offset))
      #expect(geometry.lens.minX >= 0)
      #expect(geometry.lens.maxX <= geometry.capsuleWidth)
    }
  }

  @Test func centredViewportBeforeTheFirstColumnMapsTheEmptySpace() {
    let geometry = MinimapGeometry(
      snapshot: MinimapSnapshots.strip(columns: 4, viewportOffset: -300))
    let first = geometry.cells[0]
    #expect(first.rect.minX > geometry.lens.minX + Metrics.Minimap.lensOutset)
  }

  @Test func columnsAreSeparatedByTheColumnGap() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 3))
    let gap = geometry.cells[1].rect.minX - geometry.cells[0].rect.maxX
    #expect(abs(gap - (Metrics.Minimap.columnGap + 8 * 0.1)) < 0.001)
  }

  @Test func stackedWindowsBecomeRowsSizedByTheirShares() {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: stacked(heights: [100, 300])])
    let cells = MinimapGeometry(snapshot: snapshot).cells.filter { $0.rect.minX < 60 }
    #expect(cells.count == 2)
    #expect(abs(cells[0].rect.height - 6) < 0.001)
    #expect(abs(cells[1].rect.height - 18) < 0.001)
    #expect(abs(cells[1].rect.minY - cells[0].rect.maxY - Metrics.Minimap.rowGap) < 0.001)
    #expect(abs(cells[1].rect.maxY - 33) < 0.001)
  }

  @Test func onlyTheActiveWindowOfATabbedColumnIsDrawn() {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: tabbed(windows: 3, active: 1)])
    let cells = MinimapGeometry(snapshot: snapshot).cells
    #expect(cells.count == 2)
    #expect(cells[0].id == WindowID(1))
    #expect(cells[0].content == .icon(bundleIdentifier: "app.2"))
  }

  @Test(arguments: [(2, 2), (3, 3), (5, 3)] as [(UInt32, Int)])
  func aTabbedColumnShowsTwoOrThreeDotsBelowItsContent(windows: UInt32, dots: Int) {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: tabbed(windows: windows, active: 0)])
    let cell = MinimapGeometry(snapshot: snapshot).cells[0]
    #expect(cell.tabDots.count == dots)
    #expect(cell.tabDots.allSatisfy { cell.rect.contains($0) })
    #expect(cell.tabDots.allSatisfy { $0.minY > cell.contentCenter.y })
    #expect(abs(cell.tabDots.map(\.midX).reduce(0, +) / Double(dots) - cell.rect.midX) < 0.001)
  }

  @Test func plainColumnsHaveNoDots() {
    let cells = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 3)).cells
    #expect(cells.allSatisfy { $0.tabDots.isEmpty })
  }

  @Test func wideCellsShowTheAppIcon() {
    let cells = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4)).cells
    #expect(cells.allSatisfy { $0.content == .icon(bundleIdentifier: "com.example.app") })
  }

  @Test func narrowCellsShowTheColumnNumberUpToNine() {
    let snapshot = MinimapSnapshots.strip(columns: 12, columnWidth: 292, pitch: 300)
    let cells = MinimapGeometry(snapshot: snapshot).cells
    #expect(cells[0].rect.width < Metrics.Minimap.iconMinimumWidth)
    #expect(cells[0].rect.width >= Metrics.Minimap.numberMinimumWidth)
    #expect(cells.prefix(9).map(\.content) == (1...9).map { .number($0) })
    #expect(cells[9].content == .none)
  }

  @Test(arguments: [
    (26.0, MinimapCellContent.icon(bundleIdentifier: "a")),
    (25.9, .number(3)), (12.0, .number(3)), (11.9, .none),
  ])
  func contentFollowsTheCellWidth(width: Double, expected: MinimapCellContent) {
    let content = MinimapCellContent(
      size: CGSize(width: width, height: 26), columnNumber: 3, showsNumber: true,
      bundleIdentifier: "a")
    #expect(content == expected)
  }

  @Test func aWideCellWithoutABundleIdentifierFallsBackToTheNumber() {
    let content = MinimapCellContent(
      size: CGSize(width: 40, height: 26), columnNumber: 2, showsNumber: true,
      bundleIdentifier: nil)
    #expect(content == .number(2))
  }

  @Test func rowsTooShortForAnIconKeepOnlyTheLeadNumber() {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: stacked(heights: [1, 1])])
    let cells = MinimapGeometry(snapshot: snapshot).cells.filter { $0.rect.minX < 60 }
    #expect(cells[0].content == .number(1))
    #expect(cells[1].content == .none)
  }

  @Test func cellIdentitiesAreTheWindowsAndSurviveFocusAndScrolling() {
    let first = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4)).cells
    let later = MinimapGeometry(
      snapshot: MinimapSnapshots.strip(columns: 4, focused: 2, viewportOffset: 600)).cells
    #expect(first.map(\.id) == (1...4).map { WindowID($0) })
    #expect(later.map(\.id) == first.map(\.id))
    #expect(later.filter(\.isFocused).map(\.id) == [WindowID(3)])
  }

  @Test func emptySnapshotProducesNothing() {
    let geometry = MinimapGeometry(snapshot: .empty)
    #expect(geometry.cells.isEmpty)
    #expect(geometry.lens == .zero)
    #expect(geometry.capsuleWidth == Metrics.Minimap.minimumWidth)
  }

  @Test func cellsStayInsideTheCapsule() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 12))
    #expect(geometry.cells.allSatisfy { $0.rect.minX >= 0 && $0.rect.maxX <= geometry.capsuleWidth })
    #expect(geometry.cells.allSatisfy { $0.rect.minY >= 0 && $0.rect.maxY <= Metrics.Minimap.height })
  }
}
