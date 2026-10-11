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

  @discardableResult
  public static func resetGrant() -> Bool {
    guard let identifier = Bundle.main.bundleIdentifier else { return false }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
    process.arguments = ["reset", "Accessibility", identifier]
    do {
      try process.run()
    } catch {
      return false
    }
    process.waitUntilExit()
    return process.terminationStatus == 0
  }

  public static func openSystemSettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    else { return }
    NSWorkspace.shared.open(url)
  }
}
