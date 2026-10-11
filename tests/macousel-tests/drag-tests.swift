import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragTests {
  private let pair = [Display.leftOfPair, Display.rightOfPair]

  private func launchedRow(_ count: CGWindowID = 3) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(count)
    fixture.launch()
    return (fixture, row)
  }

  private func stackAll(_ fixture: ControllerFixture) {
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
  }

  private func stackedExpectation() -> ExpectedStrip {
    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.focus(3)
    expected.apply { $0.stackFocused(into: .left) }
    return expected
  }

  @Test func releasingAfterAWidthChangeMakesTheColumnFixedWidth() throws {
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[1].frame)
    var resized = grabbed
    resized.size.width += 100

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.maxX - 2, y: grabbed.midY))
    fixture.source.userResized(row[1], to: resized)
    fixture.pointer.releasePrimary()

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(resized.width, of: WindowID(2)) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(try #require(row[1].frame).width == resized.width)
  }

  @Test func fixedWidthSurvivesADisplayResize() async throws {
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[1].frame)
    var resized = grabbed
    resized.size.width += 100
    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.maxX - 2, y: grabbed.midY))
    fixture.source.userResized(row[1], to: resized)
    fixture.pointer.releasePrimary()

    fixture.environment.displays = [.fake(width: 1400)]
    fixture.environment.onDisplaysChanged?()

    let wider = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25, on: .fake(width: 1400))
    #expect(await fixture.becomes { row[0].frame?.width == wider.frame(of: 1)?.width })
    #expect(try #require(row[1].frame).width == resized.width)
  }

  @Test func bottomEdgeHeightChangeInAStackOnlyChangesTheRowBelow() throws {
    let (fixture, row) = try launchedRow()
    stackAll(fixture)
    let before = fixture.frames(of: row)
    let grabbed = try #require(row[1].frame)
    var resized = grabbed
    resized.size.height += 40

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.maxY - 2))
    fixture.source.userResized(row[1], to: resized)
    fixture.pointer.releasePrimary()

    var expected = stackedExpectation()
    let visibleHeight = expected.display.visibleFrame.height
    let config = expected.config
    expected.apply {
      $0.setHeight(
        resized.height, of: WindowID(2), borrowingFrom: .below, viewportHeight: visibleHeight,
        config: config)
    }
    #expect(before == stackedExpectation().frames)
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(row[0].frame == before[1])
    let grownHeight = try #require(row[1].frame).height
    let shrunkHeight = try #require(row[2].frame).height
    #expect(grownHeight == (try #require(before[2])).height + 40)
    #expect(shrunkHeight == (try #require(before[3])).height - 40)
  }

  @Test func topEdgeHeightChangeInAStackBorrowsFromTheRowAbove() throws {
    let (fixture, row) = try launchedRow()
    stackAll(fixture)
    let before = fixture.frames(of: row)
    let grabbed = try #require(row[1].frame)
    var resized = grabbed
    resized.origin.y -= 40
    resized.size.height += 40

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.minY + 2))
    fixture.source.userResized(row[1], to: resized)
    fixture.pointer.releasePrimary()

    #expect(row[2].frame == before[3])
    let grownHeight = try #require(row[1].frame).height
    let shrunkHeight = try #require(row[0].frame).height
    #expect(grownHeight == (try #require(before[2])).height + 40)
    #expect(shrunkHeight == (try #require(before[1])).height - 40)
  }

  @Test func movingWithoutResizingDropsTheWindowAsAColumnAtThePointer() throws {
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[0].frame)
    let dropPoint = CGPoint(x: 500, y: grabbed.midY)

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.pointer.moveTo(dropPoint)
    fixture.source.userMoved(row[0], to: grabbed.offsetBy(dx: 380, dy: 0))
    fixture.pointer.releasePrimary()

    let expected = ExpectedStrip(columns: [2, 1, 3], fraction: 0.25)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func droppingPastTheLastColumnPutsTheWindowLast() throws {
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[0].frame)
    let dropPoint = CGPoint(x: 950, y: grabbed.midY)

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.pointer.moveTo(dropPoint)
    fixture.source.userMoved(row[0], to: grabbed.offsetBy(dx: 800, dy: 0))
    fixture.pointer.releasePrimary()

    let expected = ExpectedStrip(columns: [2, 3, 1], fraction: 0.25)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func movingAStackedWindowDropsItAsItsOwnColumn() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    let grabbed = try #require(row[1].frame)
    let dropPoint = CGPoint(x: 950, y: grabbed.midY)

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.pointer.moveTo(dropPoint)
    fixture.source.userMoved(row[1], to: grabbed.offsetBy(dx: 700, dy: 0))
    fixture.pointer.releasePrimary()

    let expected = ExpectedStrip(columns: [1, 3, 2], fraction: 0.25)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func droppingOnAnotherDisplayMovesTheWindowToThatStrip() throws {
    let fixture = try ControllerFixture(displays: pair) { $0.layout.defaultWidth = 0.25 }
    let left = [fixture.open(1, atX: 100, activating: true), fixture.open(2, atX: 400)]
    let right = [fixture.open(3, atX: 1100)]
    fixture.launch()
    let grabbed = try #require(left[0].frame)
    let dropPoint = CGPoint(x: 1600, y: grabbed.midY)

    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.pointer.moveTo(dropPoint)
    fixture.source.userMoved(left[0], to: grabbed.offsetBy(dx: 1500, dy: 0))
    fixture.pointer.releasePrimary()

    let leftExpected = ExpectedStrip(columns: [2], fraction: 0.25, on: .leftOfPair, among: pair)
    var rightExpected = ExpectedStrip(
      columns: [3, 1], fraction: 0.25, on: .rightOfPair, among: pair)
    rightExpected.focus(1)
    #expect(fixture.frames(of: [left[1]]) == leftExpected.frames)
    #expect(fixture.frames(of: [right[0], left[0]]) == rightExpected.frames)
  }

  @Test func theDraggedWindowIsNotRepositionedWhileTheButtonIsDown() throws {
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[0].frame)
    let moved = grabbed.offsetBy(dx: 300, dy: 0)
    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.pointer.moveTo(CGPoint(x: moved.midX, y: moved.midY))
    fixture.source.userMoved(row[0], to: moved)

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.moveLeft)

    #expect(row[0].frame == moved)
    #expect(row[0].framesSet.count == 1)
  }

  @Test func windowChangesWhileTheButtonIsUpAreNotDrags() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.frames(of: row)
    let grabbed = try #require(row[0].frame)

    fixture.source.userMoved(row[0], to: grabbed.offsetBy(dx: 300, dy: 0))
    fixture.pointer.releasePrimary()

    #expect(fixture.frames(of: [row[1], row[2]]) == before.filter { $0.key != 1 })
    #expect(row[0].framesSet.count == 1)
  }
}
