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
  func containerWidthFollowsTheContentWithinBounds(content: Double, expected: Double) {
    var snapshot = MinimapSnapshots.strip(columns: 2)
    snapshot.contentWidth = content
    let geometry = MinimapGeometry(snapshot: snapshot)
    #expect(abs(geometry.containerWidth - expected) < 0.001)
    #expect(geometry.containerWidth >= Metrics.Minimap.minimumWidth)
    #expect(geometry.containerWidth <= Metrics.Minimap.maximumWidth)
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

  @Test func lensStaysInsideTheContainerWhenTheViewportIsInsideTheContent() {
    for offset in [0.0, 400, 992] {
      let geometry = MinimapGeometry(
        snapshot: MinimapSnapshots.strip(columns: 4, viewportOffset: offset))
      #expect(geometry.lens.minX >= 0)
      #expect(geometry.lens.maxX <= geometry.containerWidth)
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
    #expect(abs(gap - (Metrics.Minimap.columnGap + 8 * 0.1)) <= 1)
    #expect(gap == gap.rounded())
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
    #expect(cells[0].content.icon?.bundleIdentifier == "app.2")
    #expect(cells[0].content.number?.value == 1)
  }

  @Test(arguments: [(2, 2), (3, 3), (5, 3)] as [(UInt32, Int)])
  func aTabbedColumnShowsTwoOrThreeDotsBelowItsContent(windows: UInt32, dots: Int) {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: tabbed(windows: windows, active: 0)])
    let cell = MinimapGeometry(snapshot: snapshot).cells[0]
    #expect(cell.tabDots.count == dots)
    #expect(cell.tabDots.allSatisfy { cell.rect.contains($0) })
    #expect(cell.tabDots.allSatisfy { $0.minY > cell.rect.midY })
    #expect(abs(cell.tabDots.map(\.midX).reduce(0, +) / Double(dots) - cell.rect.midX) < 0.001)
  }

  @Test func plainColumnsHaveNoDots() {
    let cells = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 3)).cells
    #expect(cells.allSatisfy { $0.tabDots.isEmpty })
  }

  private func content(
    width: Double, height: Double = 26, number: Int = 3, lead: Bool = true,
    app: String? = "a"
  ) -> MinimapCellContent {
    MinimapCellContent(
      area: CGRect(x: 10, y: 5, width: width, height: height), columnNumber: number,
      isLeadRow: lead, bundleIdentifier: app)
  }

  @Test func wideCellsShowTheIconAndTheNumberTogether() {
    let cells = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4)).cells
    #expect(cells.allSatisfy { $0.content.icon?.bundleIdentifier == "com.example.app" })
    #expect(cells.map(\.content.number?.value) == [1, 2, 3, 4])
  }

  @Test func theIconAndNumberPairIsCentredWithTheIconFirst() throws {
    let area = CGRect(x: 10, y: 5, width: Metrics.Minimap.pairMinimumWidth, height: 26)
    let result = MinimapCellContent(
      area: area, columnNumber: 3, isLeadRow: true, bundleIdentifier: "a")
    let icon = try #require(result.icon)
    let number = try #require(result.number)
    let left = icon.center.x - Metrics.Minimap.iconSide / 2
    let right = number.center.x + Metrics.Minimap.numberSlotWidth / 2
    #expect(abs((left + right) / 2 - area.midX) < 0.001)
    let gap = (number.center.x - Metrics.Minimap.numberSlotWidth / 2) - (icon.center.x + Metrics.Minimap.iconSide / 2)
    #expect(abs(gap - Metrics.Minimap.pairGap) < 0.001)
    #expect(icon.center.y == area.midY)
    #expect(number.center.y == area.midY)
  }

  @Test func justBelowThePairWidthTheNumberStandsAlone() throws {
    let result = content(width: Metrics.Minimap.pairMinimumWidth - 0.1)
    #expect(result.icon == nil)
    let number = try #require(result.number)
    #expect(number.value == 3)
    #expect(number.center == CGPoint(x: 10 + (Metrics.Minimap.pairMinimumWidth - 0.1) / 2, y: 18))
  }

  @Test func atThePairWidthBothAppear() {
    let result = content(width: Metrics.Minimap.pairMinimumWidth)
    #expect(result.icon != nil)
    #expect(result.number?.value == 3)
  }

  @Test(arguments: [12.0, 20.0, 33.9])
  func narrowCellsShowOnlyTheNumber(width: Double) {
    let result = content(width: width)
    #expect(result.icon == nil)
    #expect(result.number?.value == 3)
  }

  @Test func cellsNarrowerThanTheNumberMinimumShowNothing() {
    #expect(content(width: Metrics.Minimap.numberMinimumWidth - 0.1) == .empty)
  }

  @Test func aWideLeadCellWithoutABundleIdentifierShowsTheNumberAlone() {
    let result = content(width: 60, app: nil)
    #expect(result.icon == nil)
    #expect(result.number?.value == 3)
  }

  @Test func aLeadCellTooShortForTheIconKeepsTheNumber() {
    let result = content(width: 60, height: 12)
    #expect(result.icon == nil)
    #expect(result.number?.value == 3)
  }

  @Test func lowerRowsShowTheirIconAloneWhenWideAndTallEnough() {
    let result = content(width: 60, lead: false)
    #expect(result.icon?.bundleIdentifier == "a")
    #expect(result.number == nil)
    #expect(content(width: 25.9, lead: false) == .empty)
    #expect(content(width: 60, height: 17.9, lead: false) == .empty)
  }

  @Test func columnsPastTheNinthShowNoNumber() {
    #expect(content(width: 60, number: 9).number?.value == 9)
    let tenth = content(width: 60, number: 10)
    #expect(tenth.number == nil)
    #expect(tenth.icon?.bundleIdentifier == "a")
    #expect(content(width: 20, number: 10) == .empty)
  }

  @Test func narrowStripColumnsNumberOneToNineThenNothing() {
    let snapshot = MinimapSnapshots.strip(columns: 12, columnWidth: 292, pitch: 300)
    let cells = MinimapGeometry(snapshot: snapshot).cells
    #expect(cells[0].rect.width < Metrics.Minimap.iconMinimumWidth)
    #expect(cells[0].rect.width >= Metrics.Minimap.numberMinimumWidth)
    #expect(cells.prefix(9).map(\.content.number?.value) == (1...9).map { $0 })
    #expect(cells.prefix(9).allSatisfy { $0.content.icon == nil })
    #expect(cells[9...].allSatisfy { $0.content == .empty })
  }

  @Test func theTopRowOfAStackedColumnCarriesTheNumberAndItsIcon() {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: stacked(heights: [300, 100])])
    let cells = MinimapGeometry(snapshot: snapshot).cells.filter { $0.rect.minX < 60 }
    #expect(cells[0].content.number?.value == 1)
    #expect(cells[0].content.icon != nil)
    #expect(cells[1].content == .empty)
  }

  @Test func aTallLowerRowShowsItsIconWithoutTheNumber() {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: stacked(heights: [100, 300])])
    let cells = MinimapGeometry(snapshot: snapshot).cells.filter { $0.rect.minX < 60 }
    #expect(cells[0].content == .empty)
    #expect(cells[1].content.number == nil)
    #expect(cells[1].content.icon?.bundleIdentifier == "com.example.app")
  }

  @Test func rowsTooShortForAnIconKeepOnlyTheLeadNumber() {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: stacked(heights: [1, 1])])
    let cells = MinimapGeometry(snapshot: snapshot).cells.filter { $0.rect.minX < 60 }
    #expect(cells[0].content.number?.value == 1)
    #expect(cells[0].content.icon == nil)
    #expect(cells[1].content == .empty)
  }

  @Test func cellFramesSitOnWholePoints() {
    let snapshot = MinimapSnapshots.strip(
      columns: 7, replacing: [2: stacked(heights: [130, 270])])
    let cells = MinimapGeometry(snapshot: snapshot).cells
    for rect in cells.map(\.rect) {
      for value in [rect.minX, rect.minY, rect.width, rect.height] {
        #expect(value == value.rounded())
      }
    }
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
    #expect(geometry.containerWidth == Metrics.Minimap.minimumWidth)
  }

  @Test func cellsStayInsideTheContainer() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 12))
    #expect(geometry.cells.allSatisfy { $0.rect.minX >= 0 && $0.rect.maxX <= geometry.containerWidth })
    #expect(geometry.cells.allSatisfy { $0.rect.minY >= 0 && $0.rect.maxY <= Metrics.Minimap.height })
  }

  @Test func thePanelFrameEqualsTheContainerFrameCentredAtTheDisplayBottom() {
    let display = CGRect(x: 100, y: 50, width: 1000, height: 800)
    let frame = MinimapPanelFrame.frame(containerWidth: 228, on: display)
    #expect(frame.width == 228)
    #expect(abs(frame.height - Metrics.Minimap.height) < 0.001)
    #expect(abs(frame.midX - display.midX) < 0.001)
    #expect(abs(frame.maxY - (display.maxY - Metrics.Spacing.spacious)) < 0.001)
  }

  @Test func cellRadiusIsTheContainerRadiusMinusTheInset() {
    let cells = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4)).cells
    let expected = Metrics.Minimap.containerRadius - Metrics.Minimap.verticalPadding
    #expect(cells.allSatisfy { abs($0.cornerRadius - expected) < 0.001 })
  }

  @Test func lensRadiusIsTheContainerRadiusMinusItsOwnInset() {
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4))
    let inset = Metrics.Minimap.verticalPadding - Metrics.Minimap.lensOutset
    #expect(abs(geometry.lensRadius - (Metrics.Minimap.containerRadius - inset)) < 0.001)
    #expect(geometry.lensRadius < Metrics.Minimap.containerRadius)
    #expect(geometry.lensRadius > MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4)).cells[0].cornerRadius)
  }

  @Test(arguments: [(0.0, 14.0), (5.0, 9.0), (10.0, 4.0), (13.0, 4.0)])
  func concentricRadiusShrinksByTheInsetDownToTheFloor(inset: Double, expected: Double) {
    let container = CGSize(width: 200, height: 40)
    let rect = CGRect(x: inset, y: inset, width: 50, height: 10)
    #expect(abs(MinimapConcentricRadius.radius(of: rect, in: container) - expected) < 0.001)
  }

  @Test func shortStackedRowsCapTheirRadiusAtAThirdOfTheirHeight() {
    let snapshot = MinimapSnapshots.strip(columns: 2, replacing: [0: stacked(heights: [100, 300])])
    let cells = MinimapGeometry(snapshot: snapshot).cells.filter { $0.rect.minX < 60 }
    #expect(abs(cells[0].cornerRadius - cells[0].rect.height / 3) < 0.001)
    #expect(cells[1].cornerRadius <= cells[1].rect.height / 3 + 0.001)
    #expect(cells[1].cornerRadius < Metrics.Minimap.containerRadius - Metrics.Minimap.verticalPadding)
  }
}
