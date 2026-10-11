import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct MultiDisplayTests {
  private let pair = [Display.leftOfPair, Display.rightOfPair]

  @Test func eachDisplayGetsItsOwnStripGroupedByWhereTheWindowSits() throws {
    let fixture = try ControllerFixture(displays: pair)
    let leftOuter = fixture.open(1, atX: 500)
    let rightFirst = fixture.open(2, atX: 1100)
    let leftInner = fixture.open(3, atX: 100)
    let rightSecond = fixture.open(4, atX: 1400)

    fixture.launch()

    let leftExpected = ExpectedStrip(columns: [3, 1], on: .leftOfPair, among: pair)
    let rightExpected = ExpectedStrip(columns: [2, 4], on: .rightOfPair, among: pair)
    #expect(fixture.frames(of: [leftInner, leftOuter]) == leftExpected.frames)
    #expect(fixture.frames(of: [rightFirst, rightSecond]) == rightExpected.frames)
  }

  @Test func disabledDisplayIsLeftAlone() throws {
    let fixture = try ControllerFixture(displays: pair) {
      $0.disabledDisplays = [Display.rightOfPair.uuid]
    }
    let tiled = fixture.open(1, atX: 100)
    let untouched = fixture.open(2, atX: 1100)

    fixture.launch()

    let expected = ExpectedStrip(columns: [1], on: .leftOfPair, among: pair)
    #expect(tiled.frame == expected.frame(of: 1))
    #expect(untouched.framesSet.isEmpty)
  }

  @Test func windowsOfADisabledDisplayAreNeverClaimedByAnotherStrip() throws {
    let fixture = try ControllerFixture(displays: pair) {
      $0.disabledDisplays = [Display.leftOfPair.uuid]
    }
    let untouched = fixture.open(1, atX: 100)
    let tiled = fixture.open(2, atX: 1100)

    fixture.launch()

    let expected = ExpectedStrip(columns: [2], on: .rightOfPair, among: pair)
    #expect(untouched.framesSet.isEmpty)
    #expect(tiled.frame == expected.frame(of: 2))
  }

  @Test func spaceChangeSwapsToADifferentStripAndBack() async throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let first = fixture.open(1, atX: 100)
    let second = fixture.open(2, atX: 400)
    let third = fixture.open(3, atX: 100)
    let fourth = fixture.open(4, atX: 400)
    fixture.environment.hide(3)
    fixture.environment.hide(4)
    fixture.launch()
    fixture.manager.perform(.cycleWidth)
    var firstSpace = ExpectedStrip(columns: [1, 2], fraction: 0.25)
    firstSpace.strip.cycleWidth(config: firstSpace.config)
    #expect(fixture.frames(of: [first, second]) == firstSpace.frames)
    let framesBeforeSwitch = first.framesSet.count + second.framesSet.count

    fixture.environment.switchSpace(of: fixture.display, to: 2, showing: [3, 4])

    let secondSpace = ExpectedStrip(columns: [3, 4], fraction: 0.25)
    #expect(await fixture.becomes { fixture.frames(of: [third, fourth]) == secondSpace.frames })
    #expect(first.framesSet.count + second.framesSet.count == framesBeforeSwitch)

    fixture.environment.switchSpace(of: fixture.display, to: 1, showing: [1, 2])
    fixture.source.focus(first)

    #expect(await fixture.becomes { fixture.overlays.focusBorder?.frame == first.frame })
    fixture.manager.perform(.cycleWidth)
    firstSpace.strip.cycleWidth(config: firstSpace.config)
    #expect(fixture.frames(of: [first, second]) == firstSpace.frames)
    #expect(fixture.frames(of: [third, fourth]) == secondSpace.frames)
  }
}
