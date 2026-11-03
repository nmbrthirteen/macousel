import AppKit
import WindowSystem

final class SystemDesktopEnvironment: DesktopEnvironment {
  private let observer = EnvironmentObserver()
  private let trust = AccessibilityTrustObserver()
  private let grants = AccessibilityGrantHistory(
    defaults: .standard, build: BundleInfo(bundle: .main).build)

  var isAccessibilityGranted: Bool {
    let granted = AccessibilityPermission.isGranted
    if granted { grants.recordGranted() }
    return granted
  }

  var onAccessibilityChanged: (() -> Void)? {
    get { trust.onChange }
    set { trust.onChange = newValue }
  }

  var bootSessionIdentifier: String { BootSession.identifier }

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
    guard grants.takeStaleGrantReset(isGranted: AccessibilityPermission.isGranted) else {
      AccessibilityPermission.requestWithPrompt()
      return
    }
    Task {
      await AccessibilityPermission.resetGrant()
      AccessibilityPermission.requestWithPrompt()
    }
  }

  func currentSpace(of display: Display) -> UInt64 {
    Spaces.currentSpace(of: display)
  }

  func onScreenWindowIDs() -> Set<CGWindowID> {
    Spaces.onScreenWindowIDs()
  }

  func orderedOnScreenWindowIDs() -> [CGWindowID] {
    Spaces.orderedOnScreenWindowIDs()
  }

  func activateOrLaunch(bundleIdentifier: String) {
    if let running = NSRunningApplication.runningApplications(
      withBundleIdentifier: bundleIdentifier
    ).first {
      running.activate()
      return
    }
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    else { return }
    NSWorkspace.shared.openApplication(
      at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
  }

  func startObserving() {
    observer.start()
  }

  func stopObserving() {
    observer.stop()
  }
}
