import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragStackingTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    return (fixture, row)
  }

  private func drag(_ window: FakeWindow, to point: CGPoint, in fixture: ControllerFixture) throws {
    let grabbed = try #require(window.frame)
    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.pointer.moveTo(point)
    fixture.source.userMoved(
      window, to: grabbed.offsetBy(dx: point.x - grabbed.midX, dy: point.y - grabbed.midY))
    fixture.pointer.releasePrimary()
  }

  @Test func droppingOnTheUpperMiddleStacksAboveTheTarget() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)

    try drag(row[0], to: CGPoint(x: target.midX, y: target.minY + 10), in: fixture)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 0) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.columns.last?.windows == [WindowID(1), WindowID(3)])
  }

  @Test func droppingOnTheLowerMiddleStacksBelowTheTarget() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)

    try drag(row[0], to: CGPoint(x: target.midX, y: target.maxY - 10), in: fixture)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 1) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.columns.last?.windows == [WindowID(3), WindowID(1)])
  }

  @Test func droppingNearTheEdgeStillReordersTheColumn() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)

    try drag(row[0], to: CGPoint(x: target.minX + 5, y: target.midY), in: fixture)

    let expected = ExpectedStrip(columns: [2, 1, 3], fraction: 0.25)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func droppingOnAWindowOfTheSameStackMovesItWithinTheStack() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    let target = try #require(row[1].frame)

    try drag(row[0], to: CGPoint(x: target.midX, y: target.maxY - 4), in: fixture)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.focus(3)
    expected.apply { $0.stackFocused(into: .left) }
    expected.apply { $0.stack(WindowID(1), ontoColumnOf: WindowID(2), atRow: 1) }
    #expect(expected.strip.columns[0].windows == [WindowID(2), WindowID(1), WindowID(3)])
    #expect(fixture.frames(of: row) == expected.frames)
  }
}
