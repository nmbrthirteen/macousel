import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineFloatingBuilderTests {
  private let frame = CGRect(x: 0, y: 0, width: 1600, height: 900)

  private func tile(_ id: Int32, x: Int, focused: Bool = false) -> EngineWindow {
    EngineWindow(
      windowId: id, bundleId: "app.\(id)", appName: "App \(id)", focused: focused, displayId: 1,
      frame: EngineWindow.Frame(x: x, y: 0, width: 1000, height: 800))
  }

  private func floater(_ id: Int32, visible: Bool = true, displayId: UInt32 = 1) -> EngineWindow {
    EngineWindow(
      windowId: id, bundleId: "app.\(id)", appName: "App \(id)", title: "Palette \(id)",
      floating: true, displayId: displayId,
      frame: EngineWindow.Frame(x: 100, y: 100, width: 300, height: 200), visible: visible)
  }

  private func minimap(of snapshot: EngineSnapshot) -> MinimapSnapshot? {
    let viewport = CGRect(x: 0, y: 0, width: 1000, height: 900)
    return EngineMinimapBuilder(snapshot: snapshot, viewport: viewport).build()
  }

  @Test func theOverviewListsTheVisibleFloatingWindowsApartFromTheStrip() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      tile(1, x: 0, focused: true), tile(2, x: 1000), floater(10), floater(11, visible: false),
      floater(12, displayId: 2),
    ])

    let overview = try #require(
      EngineOverviewBuilder(snapshot: snapshot, displayFrame: frame).build())

    #expect(overview.floating.map(\.window) == [WindowID(10)])
    #expect(overview.floating.first?.title == "Palette 10")
    #expect(overview.floating.first?.frame == CGRect(x: 100, y: 100, width: 300, height: 200))
    #expect(overview.columns.flatMap(\.cards).map(\.window) == [WindowID(1), WindowID(2)])
  }

  @Test func theMinimapCountsTheFloatingWindowsOnItsDisplay() throws {
    let snapshot = EngineFixtures.snapshot(of: [
      tile(1, x: 0, focused: true), tile(2, x: 1000), floater(10), floater(11),
      floater(12, displayId: 2),
    ])

    let built = try #require(minimap(of: snapshot))

    #expect(built.floatingCount == 2)
    #expect(MinimapLabel.floatingText(for: built) == "2 floating")
  }

  @Test func theMinimapLabelSaysNothingWithoutFloatingWindows() throws {
    let built = try #require(
      minimap(of: EngineFixtures.snapshot(of: [tile(1, x: 0, focused: true), tile(2, x: 1000)])))

    #expect(built.floatingCount == 0)
    #expect(MinimapLabel.floatingText(for: built) == nil)
  }

  @Test func bringingBackLooksAtFloatingWindowsOnEveryDisplayAndOffScreen() {
    let snapshot = EngineFixtures.snapshot(of: [
      tile(1, x: 0, focused: true), floater(10), floater(11, visible: false),
      floater(12, displayId: 2),
    ])

    #expect(snapshot.activeFloatingWindows.map(\.windowId) == [10, 11, 12])
    #expect(snapshot.floatingWindows.map(\.windowId) == [10])
  }
}
