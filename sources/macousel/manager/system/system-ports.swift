import WindowSystem

extension ManagerPorts {
  static func system() -> ManagerPorts {
    let tracker = WindowTracker()
    let tap = InputEventTap()
    return ManagerPorts(
      source: SystemWindowSource(tracker: tracker),
      probe: SystemWindowProbe(tracker: tracker),
      placer: SystemFramePlacer(tracker: tracker),
      clock: SystemAnimationClock(),
      environment: SystemDesktopEnvironment(),
      pointer: SystemPointerDevice(tap: tap),
      shortcuts: SystemShortcutRegistry(),
      gestures: SystemGestureInput(tap: tap),
      overlays: SystemOverlayHost(),
      crashRecovery: SystemCrashRecovery())
  }
}
