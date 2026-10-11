import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DisplayCommandTests {
  private let pair = [Display.leftOfPair, Display.rightOfPair]

  private func launchedPair() throws -> (ControllerFixture, left: [FakeWindow], right: [FakeWindow])
  {
    let fixture = try ControllerFixture(displays: pair) { $0.layout.defaultWidth = 0.25 }
    let left = [fixture.open(1, atX: 100, activating: true), fixture.open(2, atX: 400)]
    let right = [fixture.open(3, atX: 1100)]
    fixture.launch()
    return (fixture, left, right)
  }

  @Test func sendToNextDisplayMovesTheWindowBetweenStrips() throws {
    let (fixture, left, right) = try launchedPair()

    fixture.manager.perform(.sendToNextDisplay)

    let leftExpected = ExpectedStrip(columns: [2], fraction: 0.25, on: .leftOfPair, among: pair)
    var rightExpected = ExpectedStrip(columns: [3, 1], fraction: 0.25, on: .rightOfPair, among: pair)
    rightExpected.focus(1)
    #expect(fixture.frames(of: [left[1]]) == leftExpected.frames)
    #expect(fixture.frames(of: [right[0], left[0]]) == rightExpected.frames)
    #expect(left[0].focusCount == 1)
  }

  @Test func sendToNextDisplayWrapsAroundFromTheLastDisplay() throws {
    let (fixture, left, right) = try launchedPair()
    fixture.source.focus(right[0])

    fixture.manager.perform(.sendToNextDisplay)

    var leftExpected = ExpectedStrip(
      columns: [1, 3, 2], fraction: 0.25, on: .leftOfPair, among: pair)
    leftExpected.focus(3)
    #expect(fixture.frames(of: left + right) == leftExpected.frames)
  }

  @Test func sendToNextDisplayDoesNothingOnASingleDisplay() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(2)
    fixture.launch()
    let before = fixture.frames(of: row)

    fixture.manager.perform(.sendToNextDisplay)

    #expect(fixture.frames(of: row) == before)
    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func toggleFloatingTakesTheFocusedWindowOutOfTheStrip() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.source.focus(row[1])
    let floatingFrame = row[1].frame

    fixture.manager.perform(.toggleFloating)

    let expected = ExpectedStrip(columns: [1, 3], fraction: 0.25)
    #expect(fixture.frames(of: [row[0], row[2]]) == expected.frames)
    #expect(row[1].frame == floatingFrame)
  }

  @Test func toggleFloatingTwiceBringsTheWindowBackIntoTheStrip() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.source.focus(row[1])

    fixture.manager.perform(.toggleFloating)
    fixture.manager.perform(.toggleFloating)

    var expected = ExpectedStrip(columns: [1, 3, 2], fraction: 0.25)
    expected.focus(2)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func floatedWindowStaysOutAcrossLaterSynchronizations() async throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(2)
    fixture.launch()
    fixture.source.focus(row[0])
    fixture.manager.perform(.toggleFloating)
    let floatingFrame = row[0].frame

    let marker = fixture.open(3, atX: 900, activating: true)

    let expected = ExpectedStrip(columns: [2, 3], fraction: 0.25)
    #expect(await fixture.becomes { marker.frame == expected.frame(of: 3) })
    #expect(row[0].frame == floatingFrame)
  }
}
