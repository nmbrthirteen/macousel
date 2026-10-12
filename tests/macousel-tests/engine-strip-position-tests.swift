import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct EngineStripPositionTests {
  private let viewport = CGRect(x: 0, y: 0, width: 1920, height: 1080)

  @Test func countsOnlyTiledWindowsOfTheActiveWorkspace() throws {
    let snapshot = try #require(EngineFixtures.snapshot())

    let position = try #require(snapshot.stripPosition)

    #expect(position.columnCount == 3)
    #expect(position.focusedIndex == 1)
    #expect(position.columnNumber == 2)
  }

  @Test func hasNoPositionWithoutAFocusedTiledWindow() {
    let windows = [EngineFixtures.tile(1, bundle: "a"), EngineFixtures.tile(2, bundle: "b")]

    #expect(EngineFixtures.snapshot(of: windows).stripPosition == nil)
  }

  @Test func ignoresWindowsOnOtherDisplays() {
    var elsewhere = EngineFixtures.tile(3, bundle: "c")
    elsewhere.displayId = 2
    let windows = [
      EngineFixtures.tile(1, bundle: "a", focused: true), EngineFixtures.tile(2, bundle: "b"),
      elsewhere,
    ]

    #expect(EngineFixtures.snapshot(of: windows).stripPosition?.columnCount == 2)
  }

  @Test func feedsTheMenuBarIndicator() throws {
    let snapshot = try #require(EngineFixtures.snapshot())

    let presentation = MenuBarPresentation(
      status: .running, position: snapshot.stripPosition, indicator: .count)

    #expect(
      presentation.content == .symbolWithCount(symbol: MenuBarPresentation.symbolName, text: "2/3"))
    #expect(presentation.accessibilityLabel == "Macousel, column 2 of 3")
  }

  @Test func buildsEqualSingleCellMinimapColumns() throws {
    let snapshot = try #require(EngineFixtures.snapshot())

    let minimap = try #require(EngineMinimapBuilder(snapshot: snapshot, viewport: viewport).build())

    #expect(minimap.columns.count == 3)
    #expect(Set(minimap.columns.map(\.width)).count == 1)
    #expect(minimap.columns.allSatisfy { $0.rows.count == 1 })
    #expect(minimap.columns.map(\.isFocused) == [false, true, false])
    #expect(minimap.viewportWidth == 2 * 960)
  }

  @Test func skipsTheMinimapWhenEveryWindowIsVisible() {
    let windows = [
      EngineFixtures.tile(1, bundle: "a", focused: true), EngineFixtures.tile(2, bundle: "b"),
    ]

    let builder = EngineMinimapBuilder(
      snapshot: EngineFixtures.snapshot(of: windows), viewport: viewport)

    #expect(builder.build() == nil)
  }

  @Test func buildsAnOverviewWithTheRealColumnWidths() throws {
    let snapshot = try #require(EngineFixtures.snapshot())
    let frame = CGRect(x: 0, y: 0, width: 1600, height: 900)

    let overview = try #require(EngineOverviewBuilder(snapshot: snapshot, displayFrame: frame).build())

    #expect(overview.columns.count == 3)
    #expect(overview.columns.map(\.cards.count) == [1, 1, 1])
    #expect(overview.selection == WindowID(322))
    #expect(overview.columns[0].width == 960)
  }

  @Test func mapsAMinimapWindowBackToItsColumn() throws {
    let snapshot = try #require(EngineFixtures.snapshot())

    #expect(snapshot.columnIndex(of: WindowID(323)) == 2)
    #expect(snapshot.columnIndex(of: WindowID(324)) == nil)
  }

  @Test func cyclesThroughAnAppsColumns() {
    let windows = [
      EngineFixtures.tile(1, bundle: "mail", focused: true), EngineFixtures.tile(2, bundle: "web"),
      EngineFixtures.tile(3, bundle: "mail"),
    ]
    let snapshot = EngineFixtures.snapshot(of: windows)

    let nextMail = EngineAppCycler.choice(bundleIdentifier: "mail", in: snapshot)
    let web = EngineAppCycler.choice(bundleIdentifier: "web", in: snapshot)

    #expect(nextMail == .focusWindow(WindowID(3)))
    #expect(web == .focusWindow(WindowID(2)))
    #expect(EngineAppCycler.choice(bundleIdentifier: "chat", in: snapshot) == .activateApp)
    #expect(EngineAppCycler.choice(bundleIdentifier: "mail", in: nil) == .activateApp)
  }
}
