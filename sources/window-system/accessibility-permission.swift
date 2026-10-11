import AppKit
import ApplicationServices

public enum AccessibilityPermission {
  public static var isGranted: Bool {
    AXIsProcessTrusted()
  }

  public static func requestWithPrompt() {
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
  }

  public static func openSystemSettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    else { return }
    NSWorkspace.shared.open(url)
  }
}
