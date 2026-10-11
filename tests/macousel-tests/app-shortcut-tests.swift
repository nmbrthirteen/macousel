import Carbon.HIToolbox
import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct AppShortcutTests {
  private let browserKey = Hotkey(keyCode: UInt16(kVK_ANSI_B), modifiers: [.control, .option])
  private let pair = [Display.rightOfPair, Display.leftOfPair]

  private func fixture(
    displays: [Display] = [.fake()], app: FakeApp = .browser
  ) throws -> ControllerFixture {
    let shortcut = AppShortcut(bundleIdentifier: app.bundleIdentifier, hotkey: browserKey)
    return try ControllerFixture(displays: displays) { $0.appShortcuts = [shortcut] }
  }

  private func focusedID(_ fixture: ControllerFixture) -> CGWindowID? {
    fixture.source.focusedWindow()?.id
  }

  @Test func focusesTheAppsLastFocusedWindow() async throws {
    let fixture = try fixture()
    fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.open(2, app: .browser, atX: 300)
    let lastBrowser = fixture.open(3, app: .browser, atX: 500)
    fixture.launch()
    fixture.source.focus(lastBrowser)
    fixture.source.focus(try #require(fixture.source.window(1) as? FakeWindow))

    fixture.shortcuts.trigger(browserKey)

    #expect(focusedID(fixture) == 3)
    #expect(await fixture.becomes { fixture.overlays.focusBorder?.frame == lastBrowser.frame })
  }

  @Test func fallsBackToTheFirstWindowInStripOrder() throws {
    let fixture = try fixture()
    fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.open(2, app: .browser, atX: 500)
    fixture.open(3, app: .browser, atX: 300)
    fixture.launch()

    fixture.shortcuts.trigger(browserKey)

    #expect(focusedID(fixture) == 3)
  }

  @Test func cyclesThroughTheAppsWindowsAcrossDisplaysAndWraps() throws {
    let fixture = try fixture(displays: pair)
    fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.open(2, app: .browser, atX: 400)
    fixture.open(3, app: .browser, atX: 1100)
    fixture.open(4, app: .editor, atX: 1300)
    fixture.open(5, app: .browser, atX: 1500)
    fixture.launch()

    var visited: [CGWindowID?] = []
    for _ in 0..<4 {
      fixture.shortcuts.trigger(browserKey)
      visited.append(focusedID(fixture))
    }

    #expect(visited == [2, 3, 5, 2])
  }

  @Test func activatesARunningAppWithNoTiledWindow() throws {
    let fixture = try fixture()
    fixture.open(1, app: .editor, atX: 100, activating: true)
    let panel = fixture.open(2, app: .browser, atX: 300)
    panel.isTileable = false
    fixture.environment.runningBundleIdentifiers = [FakeApp.browser.bundleIdentifier]
    fixture.launch()

    fixture.shortcuts.trigger(browserKey)

    #expect(fixture.environment.activatedApps == [FakeApp.browser.bundleIdentifier])
    #expect(fixture.environment.launchedApps.isEmpty)
  }

  @Test func launchesAnAppThatIsNotRunning() throws {
    let fixture = try fixture()
    fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.launch()

    fixture.shortcuts.trigger(browserKey)

    #expect(fixture.environment.launchedApps == [FakeApp.browser.bundleIdentifier])
    #expect(fixture.environment.activatedApps.isEmpty)
  }

  @Test func closesTheOverviewBeforeJumping() throws {
    let fixture = try fixture()
    fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.open(2, app: .browser, atX: 300)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)
    #expect(fixture.overlays.overview != nil)

    fixture.shortcuts.trigger(browserKey)

    #expect(fixture.overlays.overview == nil)
    #expect(focusedID(fixture) == 2)
  }

  @Test func closesTheOverviewBeforeLaunching() throws {
    let fixture = try fixture()
    fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)

    fixture.shortcuts.trigger(browserKey)

    #expect(fixture.overlays.overview == nil)
    #expect(fixture.environment.launchedApps == [FakeApp.browser.bundleIdentifier])
  }

  @Test func bindingIsPresentWhileTiling() throws {
    let fixture = try fixture()
    fixture.launch()

    #expect(fixture.shortcuts.boundHotkeys.contains(browserKey))
  }

  @Test func bindingIsAbsentWhilePausedAndReturnsOnResume() throws {
    let fixture = try fixture()
    fixture.launch()

    fixture.manager.perform(.togglePaused)
    #expect(!fixture.shortcuts.boundHotkeys.contains(browserKey))

    fixture.manager.perform(.togglePaused)
    #expect(fixture.shortcuts.boundHotkeys.contains(browserKey))
  }

  @Test func bindingIsAbsentWhileRecordingAShortcut() throws {
    let fixture = try fixture()
    fixture.launch()

    fixture.store.isRecordingShortcut = true
    #expect(!fixture.shortcuts.boundHotkeys.contains(browserKey))

    fixture.store.isRecordingShortcut = false
    #expect(fixture.shortcuts.boundHotkeys.contains(browserKey))
  }
}
