import Foundation
import WindowSystem

extension PaneruEngine {
  static func system(
    store: PreferencesStore, environment: any DesktopEnvironment, shortcuts: any ShortcutRegistry,
    overlays: any OverlayHost = SystemOverlayHost(),
    pointer: any PointerDevice = SystemPointerDevice(tap: InputEventTap()),
    clock: any AnimationClock = SystemAnimationClock(), bundle: Bundle = .main,
    polling: AccessibilityMonitor.Intervals = .standard
  ) -> PaneruEngine {
    let paths = EnginePaths.system()
    let log = EngineLog(url: paths.log)
    let locator = EngineHelperLocator.system(bundle: bundle)
    let locate: () -> URL? = { locator.helper }
    let service = EngineService.privateName(bundleIdentifier: bundle.bundleIdentifier)
    let commands = EngineClient(service: service, locate: locate)
    let sync = EngineConfigSync(
      store: store, writer: EngineConfigWriter(opener: SystemConfigFileOpener()), url: paths.config)
    let supervisor = EngineSupervisor(
      EngineSupervisor.Dependencies(
        launcher: SystemEngineLauncher(log: log), commands: commands,
        standalone: EngineClient(service: EngineService.standalone, locate: locate),
        plan: {
          locate().map {
            EngineLaunch.daemon(
              helper: $0, paths: paths, service: service,
              base: ProcessInfo.processInfo.environment)
          }
        },
        isTrusted: { environment.isAccessibilityGranted }, writeConfig: { try sync.writeCurrent() },
        now: { ContinuousClock.now }, sleep: { try await Task.sleep(for: $0) },
        pause: { Thread.sleep(forTimeInterval: $0.timeInterval) }))
    let displays: () -> [Display] = { environment.displays }
    let reorder = EngineReorder(commands: commands, sleep: { try await Task.sleep(for: $0) })
    let world = EngineWorld(commands: commands, sleep: { try await Task.sleep(for: $0) })
    let overview = EngineOverview(host: overlays, displays: displays, reorder: reorder)
    let drag = EngineDrag(
      pointer: pointer, clock: clock, host: overlays, world: world, displays: displays,
      reorder: reorder,
      settler: EngineSettler(commands: commands, sleep: { try await Task.sleep(for: $0) }),
      isSuppressed: { overview.isOpen })
    return PaneruEngine(
      PaneruEngineParts(
        store: store, environment: environment, supervisor: supervisor, sync: sync,
        commands: commands, events: EngineSubscriber(service: service, locate: locate),
        world: world,
        minimap: EngineMinimap(host: overlays, store: store, displays: displays, reorder: reorder),
        overview: overview, drag: drag,
        bindings: PaneruInputBindings(store: store, shortcuts: shortcuts),
        appShortcuts: EngineAppShortcuts(
          commands: commands, activate: { environment.activateOrLaunch(bundleIdentifier: $0) }),
        polling: polling,
        reporter: EngineReporter(
          version: locator.version, locate: locate, supervisor: supervisor, sync: sync, log: log)))
  }
}
