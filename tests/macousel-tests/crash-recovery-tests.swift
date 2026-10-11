import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct CrashRecoveryTests {
  private var pauseHotkeys: Set<Hotkey> {
    Set(Action.defaultShortcuts[.togglePaused] ?? [])
  }

  private func crashedSession() throws -> (
    suite: IsolatedDefaults, originals: [CGWindowID: CGRect], tiled: [CGWindowID: CGRect]
  ) {
    let suite = try IsolatedDefaults()
    let first = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    let row = first.openRow(3)
    let originals = first.frames(of: row)
    first.launch()
    return (suite, originals, first.frames(of: row))
  }

  private func recoveringFixture(
    suite: IsolatedDefaults, tiled: [CGWindowID: CGRect]
  ) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture(suite: suite)
    fixture.crashRecovery.isRecoveringFromCrash = true
    let row = tiled.keys.sorted().map { fixture.open($0) }
    for window in row { window.frame = tiled[window.id] }
    return (fixture, row)
  }

  @Test func normalStartArmsTheWatchdog() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(2)

    fixture.launch()

    #expect(fixture.crashRecovery.isArmed)
    #expect(fixture.crashRecovery.armCount == 1)
  }

  @Test func pausingDisarmsAndResumingArmsAgain() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(2)
    fixture.launch()

    fixture.manager.perform(.togglePaused)
    #expect(!fixture.crashRecovery.isArmed)

    fixture.manager.perform(.togglePaused)
    #expect(fixture.crashRecovery.isArmed)
    #expect(fixture.crashRecovery.armCount == 2)
  }

  @Test func shutdownDisarmsTheWatchdog() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(2)
    fixture.launch()

    fixture.quit()

    #expect(!fixture.crashRecovery.isArmed)
  }

  @Test func recoveryStartRestoresSavedFramesWithoutTiling() throws {
    let (suite, originals, tiled) = try crashedSession()
    let (fixture, row) = try recoveringFixture(suite: suite, tiled: tiled)
    let stray = fixture.open(99, app: .browser, atX: 700)
    let strayFrame = stray.frame

    fixture.launch()

    #expect(fixture.frames(of: row) == originals)
    #expect(stray.frame == strayFrame)
    #expect(stray.framesSet.isEmpty)
    #expect(fixture.placer.submissions.isEmpty)
  }

  @Test func recoveryStartEndsPausedWithOnlyThePauseShortcut() throws {
    let (suite, _, tiled) = try crashedSession()
    let (fixture, _) = try recoveringFixture(suite: suite, tiled: tiled)

    fixture.launch()

    #expect(fixture.manager.status == .paused)
    #expect(!pauseHotkeys.isEmpty)
    #expect(fixture.shortcuts.boundHotkeys == pauseHotkeys)
    #expect(fixture.source.isStarted)
    #expect(fixture.environment.isObserving)
  }

  @Test func recoveryStartDoesNotArmTheWatchdog() throws {
    let (suite, _, tiled) = try crashedSession()
    let (fixture, _) = try recoveringFixture(suite: suite, tiled: tiled)

    fixture.launch()

    #expect(fixture.crashRecovery.armCount == 0)
  }

  @Test func thePauseShortcutResumesTilingAfterRecovery() throws {
    let (suite, _, tiled) = try crashedSession()
    let (fixture, row) = try recoveringFixture(suite: suite, tiled: tiled)
    fixture.launch()
    let hotkey = try #require(pauseHotkeys.first)

    fixture.shortcuts.trigger(hotkey)

    #expect(fixture.manager.status == .running)
    #expect(fixture.crashRecovery.isArmed)
    #expect(row.allSatisfy { $0.frame != nil })
    #expect(!fixture.placer.submissions.isEmpty)
  }

  @Test func recoveryWaitsForAccessibilityBeforeRestoring() async throws {
    let (suite, originals, tiled) = try crashedSession()
    let (fixture, row) = try recoveringFixture(suite: suite, tiled: tiled)
    fixture.environment.isAccessibilityGranted = false
    fixture.launch()
    #expect(fixture.frames(of: row) == tiled)

    fixture.environment.isAccessibilityGranted = true

    #expect(await fixture.becomes { fixture.frames(of: row) == originals })
    #expect(fixture.manager.status == .paused)
  }
}
