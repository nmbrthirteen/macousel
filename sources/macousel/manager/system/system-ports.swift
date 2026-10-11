import WindowSystem

extension ManagerPorts {
  static func system() -> ManagerPorts {
    let tracker = WindowTracker()
    return ManagerPorts(
      source: SystemWindowSource(tracker: tracker),
      placer: SystemFramePlacer(tracker: tracker),
      clock: SystemAnimationClock(),
      environment: SystemDesktopEnvironment(),
      pointer: SystemPointerDevice(),
      shortcuts: SystemShortcutRegistry(),
      gestures: SystemGestureInput(),
      overlays: SystemOverlayHost(),
      crashRecovery: SystemCrashRecovery())
  }
}
