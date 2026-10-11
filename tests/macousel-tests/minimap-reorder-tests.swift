import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct MinimapReorderTests {
  private func launched() throws -> (ControllerFixture, MinimapModelFixtureBridge) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    _ = fixture.openRow(6)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    return (fixture, MinimapModelFixtureBridge(fixture))
  }

  private func windows(_ fixture: ControllerFixture) -> [[UInt32]]? {
    fixture.overlays.minimap?.columns.map { $0.rows.map(\.window.rawValue) }
  }

  @Test func draggingACellReordersTheRealStrip() throws {
    let (fixture, bridge) = try launched()
    let cell = try bridge.model.cell(1)
    let last = try bridge.model.cell(4).rect
    bridge.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: last.maxX - 2, y: last.midY))
    #expect(windows(fixture) == [[2], [3], [4], [1], [5], [6]])
    #expect(fixture.overlays.minimap?.columns.firstIndex { $0.isFocused } == 0)
  }

  @Test func droppingOnTheLowerHalfStacksTheWindowUnderTheDestination() throws {
    let (fixture, bridge) = try launched()
    let cell = try bridge.model.cell(1)
    let destination = try bridge.model.cell(3).rect
    bridge.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: destination.midX, y: destination.maxY - 2))
    #expect(windows(fixture) == [[2], [3, 1], [4], [5], [6]])
  }

  @Test func droppingOnTheUpperHalfStacksTheWindowAboveTheDestination() throws {
    let (fixture, bridge) = try launched()
    let cell = try bridge.model.cell(1)
    let destination = try bridge.model.cell(3).rect
    bridge.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: destination.midX, y: destination.minY + 2))
    #expect(windows(fixture) == [[2], [1, 3], [4], [5], [6]])
  }

  @Test func releasingOutsideLeavesTheRealStripUntouched() throws {
    let (fixture, bridge) = try launched()
    let before = windows(fixture)
    let cell = try bridge.model.cell(1)
    let start = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
    bridge.model.pressed(at: start)
    bridge.model.dragged(to: CGPoint(x: start.x + 60, y: start.y))
    bridge.model.released(at: CGPoint(x: start.x + 60, y: -90))
    #expect(windows(fixture) == before)
  }

  @Test func clickingACellFocusesItsWindow() throws {
    let (fixture, bridge) = try launched()
    let cell = try bridge.model.cell(5)
    bridge.model.click(CGPoint(x: cell.rect.midX, y: cell.rect.midY))
    #expect(fixture.overlays.minimap?.columns.firstIndex { $0.isFocused } == 4)
  }

  @Test func theReorderedMinimapIsPublishedAfterTheMove() throws {
    let (fixture, bridge) = try launched()
    let cell = try bridge.model.cell(1)
    let last = try bridge.model.cell(4).rect
    bridge.model.drag(
      from: CGPoint(x: cell.rect.midX, y: cell.rect.midY),
      to: CGPoint(x: last.maxX - 2, y: last.midY))
    #expect(bridge.model.snapshot == fixture.overlays.minimap)
    #expect(bridge.model.arrangement == bridge.model.snapshot)
  }
}
