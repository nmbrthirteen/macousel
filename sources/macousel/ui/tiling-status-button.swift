import SwiftUI
import WindowSystem

// The title names what a click does. The tooltip and VoiceOver value carry the current status.
struct TilingStatusButton: View {
  let manager: WindowManager

  var body: some View {
    Button(title, systemImage: symbol, action: act)
      .labelStyle(.titleAndIcon)
      .help(status)
      .accessibilityValue(status)
  }

  private var title: String {
    switch manager.status {
    case .running: "Pause tiling"
    case .paused: "Resume tiling"
    case .needsPermission: "Grant access"
    }
  }

  private var symbol: String {
    switch manager.status {
    case .running: "pause"
    case .paused: "play"
    case .needsPermission: "exclamationmark.triangle"
    }
  }

  private var status: String {
    switch manager.status {
    case .running: "Tiling is running"
    case .paused: "Tiling is paused"
    case .needsPermission: "Tiling needs Accessibility access"
    }
  }

  private func act() {
    switch manager.status {
    case .running, .paused:
      manager.perform(.togglePaused)
    case .needsPermission:
      AccessibilityGuide.shared.begin()
    }
  }
}
