import AppKit
import WindowSystem

extension AccessibilityGuide {
  // One guide for the whole app, so the welcome guide, Settings, and the menu never stack two
  // helper panels beside System Settings.
  static let shared = AccessibilityGuide.system()

  static func system() -> AccessibilityGuide {
    let panel = AccessibilityGuidePanel()
    let trust = AccessibilityTrustObserver()
    let grants = AccessibilityGrantHistory(
      defaults: .standard, build: BundleInfo(bundle: .main).build)
    return AccessibilityGuide(
      dependencies: Dependencies(
        isGranted: { AccessibilityPermission.isGranted },
        wasGrantedToAnotherBuild: {
          grants.wasGrantedToAnotherBuild(isGranted: AccessibilityPermission.isGranted)
        },
        openSettings: AccessibilityPermission.openSystemSettings,
        resetGrant: { await AccessibilityPermission.resetGrant() },
        showHelper: panel.show, hideHelper: panel.hide,
        bringToFront: { NSApp.activate() },
        watchTrust: { trust.onChange = $0 },
        sleep: { try await Task.sleep(for: $0) }))
  }
}
