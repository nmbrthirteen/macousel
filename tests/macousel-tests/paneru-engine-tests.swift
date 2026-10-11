import Carbon.HIToolbox
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct PaneruEngineTests {
  private let harness = EngineHarness()
  private let environment = FakeDesktopEnvironment(displays: [.fake()])
  private let shortcuts = FakeShortcutRegistry()

  private var pauseHotkeys: Set<Hotkey> { Set(Action.defaultShortcuts[.togglePaused] ?? []) }
  private var overviewHotkeys: Set<Hotkey> { Set(Action.defaultShortcuts[.toggleOverview] ?? []) }

  private func makeEngine(
    configure: (inout Preferences) -> Void = { _ in }
  ) throws -> (PaneruEngine, PreferencesStore) {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    configure(&store.preferences)
    return (harness.makeEngine(store: store, environment: environment, shortcuts: shortcuts), store)
  }

  private func running(
    configure: (inout Preferences) -> Void = { _ in }
  ) async throws -> (PaneruEngine, PreferencesStore) {
    let (engine, store) = try makeEngine(configure: configure)
    engine.start()
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })
    return (engine, store)
  }

  @Test func bindsOnlyTheShortcutsMacouselHandlesItself() async throws {
    let (engine, _) = try await running()

    #expect(engine.status == .running)
    #expect(shortcuts.boundHotkeys == pauseHotkeys.union(overviewHotkeys))
  }

  @Test func doesNotSpawnWithoutAccessibility() throws {
    environment.isAccessibilityGranted = false
    let (engine, _) = try makeEngine()

    engine.start()

    #expect(engine.status == .needsPermission)
    #expect(harness.launcher.launches.isEmpty)
    #expect(environment.accessibilityRequests == 1)
  }

  @Test func pausingStopsTheEngineAndKeepsOnlyThePauseShortcut() async throws {
    let (engine, _) = try await running()

    engine.perform(.togglePaused)

    #expect(engine.status == .paused)
    #expect(harness.log.entries.contains("terminate"))
    #expect(shortcuts.boundHotkeys == pauseHotkeys)
  }

  @Test func resumingStartsTheEngineAgain() async throws {
    let (engine, _) = try await running()
    engine.perform(.togglePaused)

    engine.perform(.togglePaused)

    #expect(await harness.eventually { harness.launcher.processes.count == 2 })
    #expect(engine.status == .running)
  }

  @Test func losingAccessibilityStopsTheEngineUntilItReturns() async throws {
    let (engine, _) = try await running()

    environment.isAccessibilityGranted = false

    #expect(await harness.eventually { engine.status == .needsPermission })
    #expect(harness.log.entries.contains("terminate"))
    #expect(shortcuts.boundHotkeys.isEmpty)
    environment.isAccessibilityGranted = true
    #expect(await harness.eventually { harness.launcher.processes.count == 2 })
    #expect(engine.status == .running)
  }

  @Test func shuttingDownStopsTheEngine() async throws {
    let (engine, _) = try await running()

    engine.shutdown()

    #expect(harness.log.entries.contains("terminate"))
    #expect(shortcuts.boundHotkeys.isEmpty)
  }

  @Test func forwardsMappedActionsAsSendCommands() async throws {
    let (engine, _) = try await running()

    engine.perform(.focusLeft)
    engine.perform(.popOutRight)
    engine.perform(.moveToColumn(2))

    #expect(
      await harness.eventually {
        harness.commands.sent == [["window", "focus", "west"], ["window", "unstack"]]
      })
  }

  @Test func dropsEngineActionsWhilePaused() async throws {
    let (engine, _) = try await running()
    engine.perform(.togglePaused)

    engine.perform(.focusLeft)
    await Task.yield()

    #expect(harness.commands.sent.isEmpty)
  }

  @Test func reportsAStandaloneInstanceAndRetriesOnResume() async throws {
    harness.standalone.isAlive = true
    let (engine, _) = try makeEngine()

    engine.start()

    #expect(await harness.eventually { engine.notice == EngineFailure.standaloneRunning.message })
    #expect(engine.status == .paused)
    harness.standalone.isAlive = false
    engine.perform(.togglePaused)
    #expect(await harness.eventually { engine.status == .running && engine.notice == nil })
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })
  }

  @Test func rewritesTheConfigurationInPlaceWithoutRestarting() async throws {
    let (engine, store) = try await running()
    let before = String(decoding: harness.files.handle.contents, as: UTF8.self)

    store.preferences.layout.outerGap = 20
    engine.preferencesChanged()

    let after = String(decoding: harness.files.handle.contents, as: UTF8.self)
    #expect(before != after)
    #expect(after.contains("left = 16"))
    #expect(harness.launcher.processes.count == 1)
    #expect(harness.files.handle.operations.filter { $0.hasPrefix("truncate") }.count == 2)
  }

  @Test func leavesTheFileAloneWhenNothingChanged() async throws {
    let (engine, _) = try await running()
    let writes = harness.files.handle.operations.count

    engine.preferencesChanged()

    #expect(harness.files.handle.operations.count == writes)
  }

  @Test func dropsEveryBindingWhileAShortcutIsBeingRecorded() async throws {
    let (engine, store) = try await running()

    store.isRecordingShortcut = true
    engine.preferencesChanged()
    let recording = String(decoding: harness.files.handle.contents, as: UTF8.self)
    store.isRecordingShortcut = false
    engine.preferencesChanged()
    let normal = String(decoding: harness.files.handle.contents, as: UTF8.self)

    #expect(!recording.contains("window_focus_west"))
    #expect(shortcuts.boundHotkeys == pauseHotkeys.union(overviewHotkeys))
    #expect(normal.contains("window_focus_west"))
  }

  @Test func flashesTheMinimapAndFocusesTheSelectedColumn() async throws {
    let (engine, _) = try await running()
    harness.commands.snapshot = EngineFixtures.snapshot()

    harness.events.onEvent?(.windowsChanged(workspace: 1, active: EngineActive()))
    #expect(await harness.eventually { harness.overlays.minimap != nil })
    harness.overlays.onMinimapSelect?(WindowID(323))

    #expect(
      await harness.eventually { harness.commands.sent.contains(["window", "focus", "3"]) })
    #expect(engine.position?.columnCount == 3)
  }

  @Test func opensTheOverviewAndFocusesTheChosenWindow() async throws {
    let (engine, _) = try await running()
    harness.commands.snapshot = EngineFixtures.snapshot()
    harness.events.onEvent?(.windowsChanged(workspace: 1, active: EngineActive()))
    #expect(await harness.eventually { engine.position != nil })

    engine.perform(.toggleOverview)
    #expect(harness.overlays.overview?.snapshot.columns.count == 3)
    harness.overlays.onOverviewSelect?(WindowID(321))

    #expect(
      await harness.eventually { harness.commands.sent.contains(["window", "focus", "1"]) })
    #expect(harness.overlays.overview == nil)
  }

  @Test func appShortcutsFocusTheAppsColumn() async throws {
    let hotkey = Hotkey(keyCode: UInt16(kVK_ANSI_E), modifiers: [.control, .option, .shift])
    let (engine, _) = try await running {
      $0.appShortcuts = [AppShortcut(bundleIdentifier: "com.apple.TextEdit", hotkey: hotkey)]
    }
    harness.commands.snapshot = EngineFixtures.snapshot()

    shortcuts.trigger(hotkey)

    #expect(
      await harness.eventually { harness.commands.sent.contains(["window", "focus", "3"]) })
    #expect(engine.status == .running)
  }

  @Test func appShortcutsActivateAnAppWithoutWindows() async throws {
    let hotkey = Hotkey(keyCode: UInt16(kVK_ANSI_E), modifiers: [.control, .option, .shift])
    let (engine, _) = try await running {
      $0.appShortcuts = [AppShortcut(bundleIdentifier: "com.example.Notes", hotkey: hotkey)]
    }
    harness.commands.snapshot = EngineFixtures.snapshot()

    shortcuts.trigger(hotkey)

    #expect(await harness.eventually { harness.activatedApps == ["com.example.Notes"] })
    #expect(engine.status == .running)
  }
}
