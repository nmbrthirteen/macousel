import SwiftUI
import WindowSystem
import os

struct MenuBarContent: View {
  let manager: WindowManager
  let updater: Updater
  let diagnostics: DiagnosticsAction
  let onShowWelcome: () -> Void

  private static let logger = Logger(subsystem: "dev.macousel.app", category: "menu")

  var body: some View {
    Text(statusText)
      .disabled(true)

    if let notice = manager.notice {
      Text(notice)
        .disabled(true)
    }

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

    Button("Save diagnostics…") {
      Task(priority: .utility) { await diagnostics.save() }
    }
    .disabled(diagnostics.isSaving)

    if let message = diagnostics.failureMessage {
      Text(message)
        .disabled(true)
    }

    Button("Restart Macousel", action: restart)

    Divider()

    Button("Quit Macousel") {
      NSApp.terminate(nil)
    }
    .keyboardShortcut("q")
  }

  private func restart() {
    do {
      try AppRestarter().restart()
    } catch {
      Self.logger.error("Restart failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  private var statusText: String {
    switch manager.status {
    case .running: "Running"
    case .paused: "Paused"
    case .needsPermission: "Needs Accessibility access"
    }
  }
}
