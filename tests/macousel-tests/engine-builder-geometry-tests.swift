import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineBuilderGeometryTests {
  private let frame = CGRect(x: 0, y: 0, width: 1600, height: 900)

  private func window(
    _ id: Int32, x: Int, y: Int = 0, width: Int, height: Int = 800,
    focused: Bool = false, hasFrame: Bool = true
  ) -> EngineWindow {
    EngineWindow(
      windowId: id, bundleId: "app.\(id)", appName: "App \(id)", focused: focused, displayId: 1,
      frame: hasFrame ? EngineWindow.Frame(x: x, y: y, width: width, height: height) : nil)
  }

  private func builtMinimap(of snapshot: EngineSnapshot, from left: CGFloat, to right: CGFloat)
    -> MinimapSnapshot?
  {
    let viewport = CGRect(x: left, y: 0, width: right - left, height: 900)
    return EngineMinimapBuilder(snapshot: snapshot, viewport: viewport).build()
  }

  @Test func overviewKeepsColumnWidthsAndStacksRowsByHeight() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      window(1, x: 0, width: 600), window(2, x: 600, y: 0, width: 400, height: 200),
      window(3, x: 600, y: 200, width: 400, height: 600, focused: true),
    ])

    let overview = try #require(EngineOverviewBuilder(snapshot: snapshot, displayFrame: frame).build())

    #expect(overview.columns.map(\.width) == [600, 400])
    #expect(overview.columns.map(\.cards.count) == [1, 2])
    #expect(overview.columns[1].cards.map(\.heightShare) == [0.25, 0.75])
    #expect(overview.selection == WindowID(3))
    #expect(!overview.allowsResize)
  }

  @Test func overviewFallsBackToHalfTheDisplayWithoutAFrame() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      window(1, x: 0, width: 0, hasFrame: false), window(2, x: 600, width: 400),
    ])

    let overview = try #require(EngineOverviewBuilder(snapshot: snapshot, displayFrame: frame).build())

    #expect(overview.columns.map(\.width) == [800, 400])
  }

  @Test func overviewIsEmptyWithoutTiledWindows() {
    #expect(EngineOverviewBuilder(snapshot: EngineFixtures.snapshot(of: []), displayFrame: frame).build() == nil)
  }

  @Test func minimapPlacesColumnsByTheirRealWidths() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      window(1, x: 0, width: 500), window(2, x: 500, width: 700, focused: true),
      window(3, x: 1200, width: 300), window(4, x: 1500, width: 900),
    ])

    let minimap = try #require(builtMinimap(of: snapshot, from: 500, to: 1500))

    #expect(minimap.columns.map(\.x) == [0, 500, 1200, 1500])
    #expect(minimap.columns.map(\.width) == [500, 700, 300, 900])
    #expect(minimap.contentWidth == 2400)
    #expect(minimap.viewportOffset == 500)
    #expect(minimap.viewportWidth == 1000)
    #expect(minimap.columns.map(\.isFocused) == [false, true, false, false])
  }

  @Test func minimapDrawsStacksAsRowsWithTheFocusedRowActive() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      window(1, x: 0, width: 500),
      window(2, x: 500, y: 0, width: 500, height: 300),
      window(3, x: 500, y: 300, width: 500, height: 100, focused: true),
      window(4, x: 1000, width: 500),
    ])

    let minimap = try #require(builtMinimap(of: snapshot, from: 500, to: 1500))
    let stack = minimap.columns[1]

    #expect(minimap.columns.count == 3)
    #expect(stack.rows.map(\.window) == [WindowID(2), WindowID(3)])
    #expect(stack.rows.map(\.height) == [0.75, 0.25])
    #expect(stack.activeRow == 1)
    #expect(stack.isFocused)
  }

  @Test func minimapFallsBackToTheFixedWidthWithoutAFrame() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      window(1, x: 0, width: 0, focused: true, hasFrame: false),
      window(2, x: 400, width: 600),
    ])

    let minimap = try #require(builtMinimap(of: snapshot, from: 400, to: 1000))

    #expect(minimap.columns.map(\.width) == [EngineMinimapBuilder.cellWidth, 600])
    #expect(minimap.viewportOffset == EngineMinimapBuilder.cellWidth)
    #expect(minimap.viewportWidth == 600)
  }

  @Test func minimapBuildsWhenParkedColumnsOverlapTheViewportByASliver() throws {
    let strip = FakePaneruStrip(columns: [[1], [2], [3], [4]], focused: 2)
    strip.viewport = 1000...2900

    let minimap = try #require(builtMinimap(of: strip.snapshot, from: 1000, to: 2900))

    #expect(minimap.columns.count == 4)
    #expect(minimap.viewportOffset == 960)
    #expect(minimap.viewportWidth == 1920)
  }

  @Test func minimapIgnoresTheEngineVisibleFlag() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      window(1, x: 0, width: 500), window(2, x: 500, width: 500, focused: true),
      window(3, x: 1000, width: 500),
    ])

    #expect(builtMinimap(of: snapshot, from: 0, to: 1500) == nil)
    #expect(builtMinimap(of: snapshot, from: 0, to: 1000) != nil)
  }
}
