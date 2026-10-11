import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct FocusCommandTests {
  private let pair = [Display.leftOfPair, Display.rightOfPair]

  @Test func focusRightFocusesTheNextWindow() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()

    fixture.manager.perform(.focusRight)

    #expect(row[1].focusCount == 1)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[1])
  }

  @Test func focusRightScrollsTheNewlyFocusedWindowIntoView() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.focusRight)

    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.focus(4)
    let focused = try #require(row[3].frame)
    #expect(row[3].focusCount == 1)
    #expect(fixture.display.visibleFrame.contains(focused))
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func lateFocusEventFromAnEarlierKeypressDoesNotPullTheStripBack() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.focusRight)
    let settled = fixture.frames(of: row)
    fixture.source.focus(row[1])
    fixture.source.focus(row[2])

    #expect(fixture.frames(of: row) == settled)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[3])
  }

  @Test func focusEventForTheRequestedWindowEndsTheEchoPeriod() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.manager.perform(.focusRight)
    fixture.source.focus(row[1])
    fixture.source.focus(row[3])

    #expect(fixture.windowShowingFocusBorder(among: row) === row[3])
  }

  @Test func focusLeftReturnsToThePreviousWindow() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.manager.perform(.focusLast)

    fixture.manager.perform(.focusLeft)

    #expect(row[2].focusCount == 1)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[2])
  }

  @Test func focusPastTheLastColumnOnTheLeftDisplayMovesToTheRightDisplay() throws {
    let fixture = try ControllerFixture(displays: pair)
    let left = [fixture.open(1, atX: 100, activating: true), fixture.open(2, atX: 400)]
    let right = [fixture.open(3, atX: 1100), fixture.open(4, atX: 1400)]
    fixture.launch()
    fixture.manager.perform(.focusLast)

    fixture.manager.perform(.focusRight)

    #expect(right[0].focusCount == 1)
    #expect(right[1].focusCount == 0)
    #expect(left.allSatisfy { $0.focusCount <= 1 })
  }

  @Test func focusPastTheFirstColumnOnTheRightDisplayMovesBackToTheLeftDisplay() throws {
    let fixture = try ControllerFixture(displays: pair)
    let left = [fixture.open(1, atX: 100), fixture.open(2, atX: 400)]
    let right = [fixture.open(3, atX: 1100, activating: true), fixture.open(4, atX: 1400)]
    fixture.launch()

    fixture.manager.perform(.focusLeft)

    #expect(left[0].focusCount == 1)
    #expect(right[0].focusCount == 0)
  }

  @Test func focusPastTheOuterEdgeOfTheOnlyDisplayChangesNothing() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(2)
    fixture.launch()
    let before = fixture.frames(of: row)

    fixture.manager.perform(.focusLeft)

    #expect(row.allSatisfy { $0.focusCount == 0 })
    #expect(fixture.frames(of: row) == before)
  }

  @Test func shortcutPressRunsTheBoundAction() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    let hotkey = try #require(Action.defaultShortcuts[.focusRight]?.first)

    fixture.shortcuts.trigger(hotkey)

    #expect(row[1].focusCount == 1)
  }

  @Test func mouseFollowsFocusWarpsThePointerOntoTheFocusedWindow() throws {
    let fixture = try ControllerFixture { $0.mouseFollowsFocus = true }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.pointer.location = CGPoint(x: 5, y: 5)

    fixture.manager.perform(.focusRight)

    let target = try #require(row[1].frame)
    #expect(fixture.pointer.warps == [CGPoint(x: target.midX, y: target.midY)])
  }
}
