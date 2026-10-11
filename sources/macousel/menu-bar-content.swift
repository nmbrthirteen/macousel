import SwiftUI
import WindowSystem

struct MenuBarContent: View {
  let manager: WindowManager
  let updater: Updater
  let onShowWelcome: () -> Void

  var body: some View {
    Text(statusText)
      .disabled(true)

    if manager.status == .needsPermission {
      Button("Grant Accessibility access…", action: AccessibilityPermission.requestWithPrompt)
    }

    if case .available(let release) = updater.state {
      OpenUpdateButton(version: release.version)
    }

    Divider()

    Button(manager.status == .paused ? "Resume tiling" : "Pause tiling") {
      manager.perform(.togglePaused)
    }

    OpenSettingsButton()

    Button("Show welcome guide", action: onShowWelcome)

    Divider()

    Button("Quit Macousel") {
      NSApp.terminate(nil)
    }
    .keyboardShortcut("q")
  }

  private var statusText: String {
    switch manager.status {
    case .running: "Running"
    case .paused: "Paused"
    case .needsPermission: "Needs Accessibility access"
    }
  }
}
