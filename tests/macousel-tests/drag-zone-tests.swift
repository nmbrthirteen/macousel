import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragZoneTests {
  private let pair = [Display.leftOfPair, Display.rightOfPair]

  private func launchedRow(_ count: CGWindowID = 3) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(count)
    fixture.launch()
    return (fixture, row)
  }

  private func stackedPair(_ fixture: ControllerFixture) {
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
  }

  private func expectedRow(_ change: (inout Strip) -> Void) -> ExpectedStrip {
    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply(change)
    return expected
  }

  @discardableResult
  private func dropped(
    _ window: FakeWindow, at point: CGPoint, in fixture: ControllerFixture
  ) throws -> CGRect? {
    let session = try DragSession(window, in: fixture)
    session.move(to: point)
    return session.release()
  }

  @Test func upperMiddleOfAnotherWindowStacksAboveIt() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)

    let preview = try dropped(row[0], at: CGPoint(x: target.midX, y: target.minY + 10), in: fixture)

    let expected = expectedRow { $0.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 0) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.columns.last?.windows == [WindowID(1), WindowID(3)])
    #expect(preview == row[0].frame)
  }

  @Test func lowerMiddleOfAnotherWindowStacksBelowIt() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)

    let preview = try dropped(row[0], at: CGPoint(x: target.midX, y: target.maxY - 10), in: fixture)

    let expected = expectedRow { $0.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 1) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.columns.last?.windows == [WindowID(3), WindowID(1)])
    #expect(preview == row[0].frame)
  }

  @Test func leftBandOfAColumnPutsTheWindowBeforeIt() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[1].frame)

    let preview = try dropped(row[2], at: CGPoint(x: target.minX + 10, y: target.midY), in: fixture)

    let expected = expectedRow { $0.move(WindowID(3), toColumn: 1) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.columns.map(\.windows) == [[WindowID(1)], [WindowID(3)], [WindowID(2)]])
    #expect(preview == row[2].frame)
  }

  @Test func rightBandOfAColumnPutsTheWindowAfterIt() throws {
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)

    let preview = try dropped(row[0], at: CGPoint(x: target.maxX - 10, y: target.midY), in: fixture)

    let expected = expectedRow { $0.move(WindowID(1), toColumn: 2) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.columns.map(\.windows) == [[WindowID(2)], [WindowID(3)], [WindowID(1)]])
    #expect(preview == row[0].frame)
  }

  @Test func gapBetweenColumnsPutsTheWindowBetweenThem() throws {
    let (fixture, row) = try launchedRow()
    let left = try #require(row[1].frame)
    let right = try #require(row[2].frame)
    let gapMiddle = (left.maxX + right.minX) / 2

    try dropped(row[0], at: CGPoint(x: gapMiddle, y: left.midY), in: fixture)

    let expected = expectedRow { $0.move(WindowID(1), toColumn: 1) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.columns.map(\.windows) == [[WindowID(2)], [WindowID(1)], [WindowID(3)]])
  }

  @Test func pastTheLastColumnPutsTheWindowLast() throws {
    let (fixture, row) = try launchedRow()
    let last = try #require(row[2].frame)

    try dropped(row[0], at: CGPoint(x: last.maxX + 100, y: last.midY), in: fixture)

    let expected = expectedRow { $0.move(WindowID(1), toColumn: 2) }
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func pullingAWindowOutOfAStackToTheLeft() throws {
    let (fixture, row) = try launchedRow()
    stackedPair(fixture)
    let column = try #require(row[0].frame)

    let preview = try dropped(row[1], at: CGPoint(x: column.minX + 10, y: column.midY), in: fixture)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.apply { $0.move(WindowID(2), toColumn: 0) }
    #expect(expected.strip.columns.map(\.windows) == [[WindowID(2)], [WindowID(1)], [WindowID(3)]])
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(preview == row[1].frame)
  }

  @Test func pullingAWindowOutOfAStackToTheRight() throws {
    let (fixture, row) = try launchedRow()
    stackedPair(fixture)
    let column = try #require(row[0].frame)

    let preview = try dropped(row[1], at: CGPoint(x: column.maxX - 10, y: column.midY), in: fixture)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.apply { $0.move(WindowID(2), toColumn: 1) }
    #expect(expected.strip.columns.map(\.windows) == [[WindowID(1)], [WindowID(2)], [WindowID(3)]])
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(preview == row[1].frame)
  }

  @Test func droppingOnAWindowOfTheSameStackReordersIt() throws {
    let (fixture, row) = try launchedRow()
    stackedPair(fixture)
    let target = try #require(row[0].frame)

    try dropped(row[1], at: CGPoint(x: target.midX, y: target.minY + 10), in: fixture)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.apply { $0.stack(WindowID(2), ontoColumnOf: WindowID(1), atRow: 0) }
    #expect(expected.strip.columns[0].windows == [WindowID(2), WindowID(1)])
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func droppingOnAnotherDisplayMovesTheWindowToThatStrip() throws {
    let fixture = try ControllerFixture(displays: pair) { $0.layout.defaultWidth = 0.25 }
    let left = [fixture.open(1, atX: 100, activating: true), fixture.open(2, atX: 400)]
    let right = [fixture.open(3, atX: 1100)]
    fixture.launch()
    let grabbed = try #require(left[0].frame)

    let preview = try dropped(left[0], at: CGPoint(x: 1600, y: grabbed.midY), in: fixture)

    let leftExpected = ExpectedStrip(columns: [2], fraction: 0.25, on: .leftOfPair, among: pair)
    var rightExpected = ExpectedStrip(
      columns: [3, 1], fraction: 0.25, on: .rightOfPair, among: pair)
    rightExpected.focus(1)
    #expect(fixture.frames(of: [left[1]]) == leftExpected.frames)
    #expect(fixture.frames(of: [right[0], left[0]]) == rightExpected.frames)
    #expect(preview == left[0].frame)
  }

  @Test func droppingOnNothingPutsTheWindowBackInItsSlot() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let submissions = row[0].framesSet.count

    let preview = try dropped(row[0], at: CGPoint(x: 400, y: 5), in: fixture)

    #expect(preview == nil)
    #expect(fixture.overlays.dropPreview == nil)
    #expect(fixture.frames(of: row) == before)
    #expect(row[0].framesSet.count == submissions + 1)
  }

  @Test func droppingALoneColumnOnItsOwnSlotChangesNothing() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let own = try #require(row[1].frame)

    let preview = try dropped(row[1], at: CGPoint(x: own.midX, y: own.midY + 30), in: fixture)

    #expect(preview == nil)
    #expect(fixture.frames(of: row) == before)
  }

  @Test func eachPreviewStepShowsWhereTheWindowWouldLandNow() throws {
    let (fixture, row) = try launchedRow()
    let middle = try #require(row[1].frame)
    let last = try #require(row[2].frame)
    let session = try DragSession(row[0], in: fixture)

    session.move(to: CGPoint(x: last.midX, y: last.minY + 10))
    let stacked = try #require(fixture.overlays.dropPreview)
    session.move(to: CGPoint(x: middle.maxX - 10, y: middle.midY))
    let beside = try #require(fixture.overlays.dropPreview)
    session.move(to: CGPoint(x: 400, y: 5))

    #expect(stacked.height < last.height)
    #expect(beside.width == middle.width)
    #expect(fixture.overlays.dropPreview == nil)
    session.release()
    #expect(fixture.overlays.dropPreviewHistory.compactMap { $0 }.count == 2)
  }
}
