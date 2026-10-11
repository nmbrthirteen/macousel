import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct PointerAndGestureTests {
  @Test func focusFollowsMouseFocusesTheWindowUnderThePointer() throws {
    let fixture = try ControllerFixture { $0.focusFollowsMouse = true }
    let row = fixture.openRow(2)
    fixture.launch()
    let hovered = try #require(row[1].frame)
    fixture.pointer.windowAtPoint = { _ in 2 }

    fixture.pointer.moveTo(CGPoint(x: hovered.midX, y: hovered.midY))

    #expect(row[1].focusCount == 1)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[1])
  }

  @Test func focusFollowsMouseIgnoresThePointerOverTheFocusedWindow() throws {
    let fixture = try ControllerFixture { $0.focusFollowsMouse = true }
    let row = fixture.openRow(2)
    fixture.launch()
    let focused = try #require(row[0].frame)
    fixture.pointer.windowAtPoint = { _ in 1 }

    fixture.pointer.moveTo(CGPoint(x: focused.midX, y: focused.midY))

    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func focusFollowsMouseIsOffByDefault() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(2)
    fixture.launch()
    let hovered = try #require(row[1].frame)
    fixture.pointer.windowAtPoint = { _ in 2 }

    fixture.pointer.moveTo(CGPoint(x: hovered.midX, y: hovered.midY))

    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func focusFollowsMouseWaitsOutTheGraceAfterAKeyboardCommand() throws {
    let fixture = try ControllerFixture { $0.focusFollowsMouse = true }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    let hovered = try #require(row[2].frame)
    fixture.pointer.windowAtPoint = { _ in 3 }

    fixture.pointer.moveTo(CGPoint(x: hovered.midX, y: hovered.midY))

    #expect(row[2].focusCount == 0)
  }

  @Test func gesturesStartOnlyForTheEnabledPreferences() throws {
    let fixture = try ControllerFixture {
      $0.scrollGestureEnabled = false
      $0.swipeGestureEnabled = true
      $0.swipeFingers = 4
    }

    fixture.launch()

    #expect(!fixture.gestures.isScrolling)
    #expect(fixture.gestures.swipeFingerCount == 4)
  }

  @Test func changingPreferencesWhileRunningReconfiguresInputs() throws {
    let fixture = try ControllerFixture()
    fixture.launch()
    #expect(fixture.gestures.isScrolling)

    fixture.store.preferences.scrollGestureEnabled = false

    #expect(!fixture.gestures.isScrolling)
  }

  @Test func scrollGestureMovesTheStripUnderThePointer() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.gestures.onScroll?(-120, .began)

    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.strip.scrollOffset = 120
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func shortScrollRestsOnTheNearestLeftEdgeAndKeepsFocus() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    let initial = fixture.frames(of: row)

    fixture.gestures.onScroll?(-80, .began)

    #expect(await fixture.becomes { fixture.frames(of: row) == initial })
    #expect(row.allSatisfy { $0.focusCount == 0 })
    #expect(fixture.windowShowingFocusBorder(among: row) === row[0])
  }

  @Test func longScrollRestsFlushLeftAndFocusesTheFirstFullyVisibleColumn() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.gestures.onScroll?(-700, .began)

    #expect(await fixture.becomes { row[1].focusCount == 1 })
    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    let width = expected.display.visibleFrame.width
    let config = expected.config
    expected.apply { $0.settle(at: 700, viewportWidth: width, config: config) }
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(expected.strip.focusedWindow == WindowID(2))
    #expect(row[2].focusCount == 0)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[1])
  }

  @Test func displayFollowsPointerDoesNotObserveMovementOnASingleDisplay() throws {
    let fixture = try ControllerFixture { $0.displayFollowsPointer = true }
    _ = fixture.openRow(2)

    fixture.launch()

    #expect(!fixture.pointer.isObservingMovement)
  }

  @Test func displayFollowsPointerObservesMovementOnTwoDisplays() throws {
    let fixture = try ControllerFixture(displays: [.leftOfPair, .rightOfPair]) {
      $0.displayFollowsPointer = true
    }
    _ = fixture.openRow(2)

    fixture.launch()

    #expect(fixture.pointer.isObservingMovement)
  }

  @Test func focusFollowsMouseObservesMovementOnASingleDisplay() throws {
    let fixture = try ControllerFixture {
      $0.displayFollowsPointer = false
      $0.focusFollowsMouse = true
    }
    _ = fixture.openRow(2)

    fixture.launch()

    #expect(fixture.pointer.isObservingMovement)
  }
}
