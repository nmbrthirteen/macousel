import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct FocusOrderTests {
  private func launchedRow(_ count: CGWindowID = 4) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(count)
    fixture.launch()
    return (fixture, row)
  }

  private func expectFrameBeforeFocus(
    of window: CGWindowID, in fixture: ControllerFixture, since mark: Int
  ) {
    let tail = fixture.sequence.entries(since: mark)
    let submitted = tail.firstIndex(of: .frameSubmitted(window))
    let focused = tail.firstIndex(of: .focused(window))
    #expect(submitted != nil)
    #expect(focused != nil)
    if let submitted, let focused { #expect(submitted < focused) }
  }

  @Test func theWaitForPlacementIsThirtyMilliseconds() {
    #expect(FocusDriver.placementWait == .milliseconds(30))
  }

  @Test func aFocusCommandSetsTheTargetFrameBeforeFocusingIt() throws {
    let (fixture, _) = try launchedRow()
    let mark = fixture.sequence.mark

    fixture.manager.perform(.focusLast)

    expectFrameBeforeFocus(of: 4, in: fixture, since: mark)
    #expect(fixture.placer.requestedTimeouts == [FocusDriver.placementWait])
  }

  @Test func aNumberedPlaceSetsTheTargetFrameBeforeFocusingIt() throws {
    let (fixture, _) = try launchedRow()
    let mark = fixture.sequence.mark

    fixture.manager.perform(.focusColumn(4))

    expectFrameBeforeFocus(of: 4, in: fixture, since: mark)
  }

  @Test func anAppShortcutSetsTheTargetFrameBeforeFocusingIt() throws {
    let key = Hotkey(keyCode: 11, modifiers: [.control, .option])
    let fixture = try ControllerFixture {
      $0.appShortcuts = [AppShortcut(bundleIdentifier: FakeApp.browser.bundleIdentifier, hotkey: key)]
    }
    fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.open(2, app: .editor, atX: 300)
    fixture.open(3, app: .editor, atX: 500)
    fixture.open(4, app: .browser, atX: 700)
    fixture.launch()
    let mark = fixture.sequence.mark

    fixture.shortcuts.trigger(key)

    expectFrameBeforeFocus(of: 4, in: fixture, since: mark)
  }

  @Test func anOverviewSelectionSetsTheTargetFrameBeforeFocusingIt() throws {
    let (fixture, _) = try launchedRow()
    fixture.manager.perform(.toggleOverview)
    let mark = fixture.sequence.mark

    fixture.overlays.click(WindowID(4))

    expectFrameBeforeFocus(of: 4, in: fixture, since: mark)
  }

  @Test func aMinimapClickSetsTheTargetFrameBeforeFocusingIt() throws {
    let (fixture, _) = try launchedRow()
    let mark = fixture.sequence.mark

    fixture.overlays.clickMinimap(WindowID(4))

    expectFrameBeforeFocus(of: 4, in: fixture, since: mark)
  }

  @Test func aTabClickSetsTheTargetFrameBeforeFocusingIt() throws {
    let (fixture, _) = try launchedRow()
    let mark = fixture.sequence.mark

    fixture.overlays.onTabSelected?(WindowID(4))

    expectFrameBeforeFocus(of: 4, in: fixture, since: mark)
  }

  @Test func pointerDrivenFocusSubmitsFramesBeforeFocusing() throws {
    let fixture = try ControllerFixture { $0.focusFollowsMouse = true }
    let row = fixture.openRow(2)
    fixture.launch()
    let hovered = try #require(row[1].frame)
    fixture.pointer.windowAtPoint = { _ in 2 }
    let mark = fixture.sequence.mark

    fixture.pointer.moveTo(CGPoint(x: hovered.midX, y: hovered.midY))

    #expect(fixture.sequence.entries(since: mark).contains(.focused(2)))
    #expect(fixture.placer.requestedTimeouts == [FocusDriver.placementWait])
  }

  @Test func focusStillHappensAfterTheTimeoutWhenThePlacerNeverDrains() throws {
    let (fixture, row) = try launchedRow()
    fixture.placer.holdsPlacementWork = true
    let submissions = fixture.placer.submissions.count

    fixture.manager.perform(.focusLast)

    #expect(fixture.placer.submissions.count > submissions)
    #expect(row[3].focusCount == 0)
    fixture.placer.timeOutHeldPlacementWork()
    #expect(row[3].focusCount == 1)
    #expect(row[3].raisingFocusCount == 1)
  }

  @Test func aNewerFocusRequestSupersedesOneStillWaitingForPlacement() throws {
    let (fixture, row) = try launchedRow()
    fixture.placer.holdsPlacementWork = true

    fixture.manager.perform(.focusLast)
    fixture.manager.perform(.focusFirst)
    fixture.placer.timeOutHeldPlacementWork()

    #expect(row[3].focusCount == 0)
    #expect(row[0].focusCount == 1)
  }

  @Test func aWindowClosedWhileWaitingIsNotFocused() throws {
    let (fixture, row) = try launchedRow()
    fixture.placer.holdsPlacementWork = true

    fixture.manager.perform(.focusLast)
    fixture.source.close(row[3])
    fixture.placer.timeOutHeldPlacementWork()

    #expect(row[3].focusCount == 0)
  }
}
