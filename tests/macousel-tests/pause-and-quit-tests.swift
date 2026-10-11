import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct PauseAndQuitTests {
  private func launchedRow(
    configure: (inout Preferences) -> Void = { _ in }
  ) throws -> (ControllerFixture, [FakeWindow], [CGWindowID: CGRect]) {
    let fixture = try ControllerFixture(preferences: configure)
    let row = fixture.openRow(3)
    let originals = fixture.frames(of: row)
    fixture.launch()
    return (fixture, row, originals)
  }

  private var pauseHotkeys: Set<Hotkey> {
    Set(Action.defaultShortcuts[.togglePaused] ?? [])
  }

  private var allHotkeys: Set<Hotkey> {
    Set(Action.defaultShortcuts.values.flatMap { $0 })
  }

  @Test func runningBindsEveryShortcut() throws {
    let (fixture, _, _) = try launchedRow()

    #expect(fixture.shortcuts.boundHotkeys == allHotkeys)
  }

  @Test func pausingRestoresEveryWindowsOriginalFrame() throws {
    let (fixture, row, originals) = try launchedRow()
    #expect(fixture.frames(of: row) != originals)

    fixture.manager.perform(.togglePaused)

    #expect(fixture.manager.status == .paused)
    #expect(fixture.frames(of: row) == originals)
  }

  @Test func pausingUnbindsEveryShortcutExceptPause() throws {
    let (fixture, _, _) = try launchedRow()

    fixture.manager.perform(.togglePaused)

    #expect(!pauseHotkeys.isEmpty)
    #expect(fixture.shortcuts.boundHotkeys == pauseHotkeys)
  }

  @Test func pausingStopsGesturesHidesOverlaysAndHaltsTheClock() throws {
    let (fixture, _, _) = try launchedRow {
      $0.animationSpeed = .fast
      $0.swipeGestureEnabled = true
    }
    #expect(fixture.gestures.isScrolling)
    #expect(fixture.gestures.swipeFingerCount == 3)

    fixture.manager.perform(.togglePaused)

    #expect(!fixture.gestures.isScrolling)
    #expect(fixture.gestures.swipeFingerCount == nil)
    #expect(fixture.overlays.focusBorder == nil)
    #expect(!fixture.clock.isRunning)
    #expect(fixture.placer.flushCount > 0)
  }

  @Test func pausedManagerIgnoresCommands() throws {
    let (fixture, row, originals) = try launchedRow()
    fixture.manager.perform(.togglePaused)

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.moveLeft)

    #expect(fixture.frames(of: row) == originals)
    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func pauseShortcutResumesTiling() throws {
    let (fixture, row, originals) = try launchedRow()
    let tiled = fixture.frames(of: row)
    let hotkey = try #require(pauseHotkeys.first)
    fixture.shortcuts.trigger(hotkey)
    #expect(fixture.frames(of: row) == originals)

    fixture.shortcuts.trigger(hotkey)

    #expect(fixture.manager.status == .running)
    #expect(fixture.frames(of: row) == tiled)
    #expect(fixture.shortcuts.boundHotkeys == allHotkeys)
    #expect(fixture.gestures.isScrolling)
  }

  @Test func resumingRetilesWindowsThatMovedWhilePaused() throws {
    let (fixture, row, _) = try launchedRow()
    let tiled = fixture.frames(of: row)
    fixture.manager.perform(.togglePaused)
    row[0].frame = CGRect(x: 300, y: 300, width: 500, height: 400)

    fixture.manager.perform(.togglePaused)

    #expect(fixture.frames(of: row) == tiled)
  }

  @Test func recordingAShortcutUnbindsEveryShortcut() throws {
    let (fixture, _, _) = try launchedRow()

    fixture.store.isRecordingShortcut = true

    #expect(fixture.shortcuts.boundHotkeys.isEmpty)
    fixture.store.isRecordingShortcut = false
    #expect(fixture.shortcuts.boundHotkeys == allHotkeys)
  }

  @Test func shutdownRestoresOriginalFramesAndReleasesTheSystem() throws {
    let (fixture, row, originals) = try launchedRow()

    fixture.quit()

    #expect(fixture.frames(of: row) == originals)
    #expect(fixture.shortcuts.boundHotkeys.isEmpty)
    #expect(!fixture.source.isStarted)
    #expect(!fixture.environment.isObserving)
    #expect(!fixture.gestures.isScrolling)
  }

  @Test func shutdownWhilePausedLeavesWindowsWhereTheyWere() throws {
    let (fixture, row, originals) = try launchedRow()
    fixture.manager.perform(.togglePaused)

    fixture.quit()

    #expect(fixture.frames(of: row) == originals)
    #expect(fixture.shortcuts.boundHotkeys.isEmpty)
  }

  @Test func windowDraggedOffscreenReturnsOntoADisplayWhenReleased() throws {
    let fixture = try ControllerFixture()
    let window = fixture.open(1, atX: 5000, activating: true)
    fixture.launch()

    fixture.quit()

    let restored = try #require(window.frame)
    #expect(fixture.display.visibleFrame.contains(restored))
  }
}
