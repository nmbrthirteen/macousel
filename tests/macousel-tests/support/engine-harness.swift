import Foundation
import WindowSystem

@testable import Macousel

@MainActor
final class EngineHarness {
  let log = EngineCallLog()
  let launcher: FakeEngineLauncher
  let commands: FakeEngineCommands
  let standalone: FakeEngineCommands
  let events = FakeEngineEvents()
  let files = FakeConfigFiles()
  let overlays = FakeOverlayHost()
  var isTrusted = true
  var hasHelper = true
  var now = ContinuousClock.now
  private(set) var sleeps: [Duration] = []
  private(set) var pauses: [Duration] = []
  private(set) var activatedApps: [String] = []

  init() {
    launcher = FakeEngineLauncher(log: log)
    commands = FakeEngineCommands(log: log)
    standalone = FakeEngineCommands(log: log)
  }

  var configURL: URL { URL(fileURLWithPath: "/tmp/engine-harness/paneru.toml") }

  func makeSync(store: PreferencesStore) -> EngineConfigSync {
    EngineConfigSync(store: store, writer: EngineConfigWriter(opener: files), url: configURL)
  }

  func makeSupervisor(sync: EngineConfigSync) -> EngineSupervisor {
    EngineSupervisor(
      EngineSupervisor.Dependencies(
        launcher: launcher, commands: commands, standalone: standalone,
        plan: { [self] in
          hasHelper
            ? EngineLaunch(
              executable: URL(fileURLWithPath: "/tmp/paneru"), arguments: [], environment: [:])
            : nil
        },
        isTrusted: { [self] in isTrusted },
        writeConfig: { [log] in
          log.append("write config")
          try sync.writeCurrent()
        },
        now: { [self] in now },
        sleep: { [self] duration in sleeps.append(duration) },
        pause: { [self] duration in pauses.append(duration) }))
  }

  func makeEngine(
    store: PreferencesStore, environment: any DesktopEnvironment,
    shortcuts: any ShortcutRegistry
  ) -> PaneruEngine {
    let sync = makeSync(store: store)
    let supervisor = makeSupervisor(sync: sync)
    let displays: () -> [Display] = { environment.displays }
    return PaneruEngine(
      PaneruEngineParts(
        store: store, environment: environment, supervisor: supervisor, sync: sync,
        commands: commands, events: events,
        world: EngineWorld(commands: commands, sleep: { _ in }),
        minimap: EngineMinimap(host: overlays, store: store, displays: displays),
        overview: EngineOverview(host: overlays, displays: displays),
        bindings: PaneruInputBindings(store: store, shortcuts: shortcuts),
        appShortcuts: EngineAppShortcuts(
          commands: commands, activate: { [self] in activatedApps.append($0) }),
        polling: AccessibilityMonitor.Intervals(
          whileWaiting: .milliseconds(10), whileWatching: .milliseconds(10)),
        reporter: EngineReporter(
          version: "0.5.2", locate: { URL(fileURLWithPath: "/tmp/paneru") },
          supervisor: supervisor, sync: sync,
          log: EngineLog(url: URL(fileURLWithPath: "/tmp/engine-harness/engine.log")))))
  }

  func eventually(_ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + .seconds(30)
    while !condition() {
      if ContinuousClock.now > deadline { return false }
      await Task.yield()
    }
    return true
  }
}
