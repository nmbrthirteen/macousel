import AppKit
import WindowSystem

final class SystemDesktopEnvironment: DesktopEnvironment {
  private let observer = EnvironmentObserver()

  var isAccessibilityGranted: Bool { AccessibilityPermission.isGranted }

  var displays: [Display] { Display.all() }

  var frontmostProcessID: pid_t? {
    NSWorkspace.shared.frontmostApplication?.processIdentifier
  }

  var reducesMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

  var isLowPowerModeEnabled: Bool { ProcessInfo.processInfo.isLowPowerModeEnabled }

  var onDisplaysChanged: (() -> Void)? {
    get { observer.onDisplaysChanged }
    set { observer.onDisplaysChanged = newValue }
  }

  var onSpaceChanged: (() -> Void)? {
    get { observer.onSpaceChanged }
    set { observer.onSpaceChanged = newValue }
  }

  func requestAccessibilityAccess() {
    AccessibilityPermission.resetGrant()
    AccessibilityPermission.requestWithPrompt()
  }

  func currentSpace(of display: Display) -> UInt64 {
    Spaces.currentSpace(of: display)
  }

  func onScreenWindowIDs() -> Set<CGWindowID> {
    Spaces.onScreenWindowIDs()
  }

  func startObserving() {
    observer.start()
  }

  func stopObserving() {
    observer.stop()
  }
}
