import WindowSystem

struct PaneruEngineParts {
  var store: PreferencesStore
  var environment: any DesktopEnvironment
  var supervisor: EngineSupervisor
  var sync: EngineConfigSync
  var commands: any EngineCommanding
  var events: any EngineEventSource
  var world: EngineWorld
  var minimap: EngineMinimap
  var overview: EngineOverview
  var drag: EngineDrag
  var bindings: PaneruInputBindings
  var appShortcuts: EngineAppShortcuts
  var polling: AccessibilityMonitor.Intervals
  var reporter: EngineReporter
}
