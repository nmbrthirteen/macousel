import Foundation
import WindowSystem

extension PaneruEngine {
  static func system(
    store: PreferencesStore, environment: any DesktopEnvironment, shortcuts: any ShortcutRegistry,
    overlays: any OverlayHost = SystemOverlayHost(),
    pointer: (any PointerDevice)? = nil, gestures: (any GestureInput)? = nil,
    clock: any AnimationClock = SystemAnimationClock(), bundle: Bundle = .main
  ) -> PaneruEngine {
    let tap = InputEventTap()
    let pointer = pointer ?? SystemPointerDevice(tap: tap)
    let gestures = gestures ?? SystemGestureInput(tap: tap)
    let paths = EnginePaths.system()
    let log = EngineLog(url: paths.log)
    let locator = EngineHelperLocator.system(bundle: bundle)
    let locate: () -> URL? = { locator.helper }
    let service = EngineService.privateName(bundleIdentifier: bundle.bundleIdentifier)
    let bridge = EngineBridgeConnection(service: service, locate: { locator.bridge })
    let commands = EngineClient(
      service: service, locate: locate, locateBridge: { locator.bridge }, bridge: bridge)
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
        isScreenLocked: { ScreenLock.isLocked }))
    let displays: () -> [Display] = { environment.displays }
    let world = EngineWorld(commands: commands, sleep: { try await Task.sleep(for: $0) })
    let reorder = EngineReorder(commands: commands, sleep: { try await world.awaitEvent(upTo: $0) })
    let windows = SystemEngineWindowControl()
    let overview = EngineOverview(
      host: overlays, displays: displays, reorder: reorder, windows: windows)
    let drag = EngineDrag(
      pointer: pointer, clock: clock, host: overlays, world: world, displays: displays,
      reorder: reorder,
      settler: EngineSettler(commands: commands, sleep: { try await world.awaitEvent(upTo: $0) }),
      centering: EngineCentering(
        commands: commands, pointer: pointer, displays: displays,
        isEnabled: { store.preferences.layout.centerMode != .never },
        sleep: { try await Task.sleep(for: $0) }),
      isSuppressed: { overview.isOpen })
    return PaneruEngine(
      PaneruEngineParts(
        store: store, environment: environment, supervisor: supervisor, sync: sync,
        commands: commands,
        events: EngineSubscriber(service: service, bridge: bridge, locate: locate), world: world,
        minimap: EngineMinimap(host: overlays, store: store, displays: displays, reorder: reorder),
        overview: overview, reorder: reorder, drag: drag,
        swipe: EngineSwipe(
          gestures: gestures, store: store, commands: commands, position: { world.position },
          isSuppressed: { overview.isOpen }),
        bindings: PaneruInputBindings(store: store, shortcuts: shortcuts),
        appShortcuts: EngineAppShortcuts(
          commands: commands, reorder: reorder, activate: { environment.activateOrLaunch(bundleIdentifier: $0) }),
        windows: windows,
        floating: EngineFloatingKeeper(
          store: store, clock: clock, windows: windows,
          stackingOrder: { environment.orderedOnScreenWindowIDs() }),
        reporter: EngineReporter(
          version: locator.version, locate: locate, supervisor: supervisor, sync: sync, log: log)))
  }
}
