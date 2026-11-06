import SwiftUI
import WindowSystem

struct AccessibilityGrantLine: View {
  let status: AccessibilityStatus
  var guide = AccessibilityGuide.shared

  var body: some View {
    HStack(spacing: Metrics.Spacing.comfortable) {
      Label(title, systemImage: symbol)
        .foregroundStyle(status.isGranted ? Color.green : Color.secondary)
        .contentTransition(.symbolEffect(.replace))
      if guide.phase == .guiding, !status.isGranted {
        ProgressView().controlSize(.small)
      }
      Spacer(minLength: 0)
      if !status.isGranted { button }
    }
    .pollsAccessibility(status)
  }

  @ViewBuilder
  private var button: some View {
    if guide.phase == .staleGrant {
      Button("Fix access") { Task { await guide.fixStaleGrant() } }
    } else {
      Button("Open System Settings\u{2026}", action: guide.begin)
    }
  }

  private var title: String {
    if status.isGranted { return "Access granted" }
    switch guide.phase {
    case .guiding: return "Switch on Macousel in System Settings"
    case .staleGrant: return "macOS does not recognize this version of Macousel"
    case .idle, .granted: return "Access needed"
    }
  }

  private var symbol: String {
    if status.isGranted { return "checkmark.circle.fill" }
    return guide.phase == .staleGrant ? "exclamationmark.circle.fill" : "lock.circle.fill"
  }
}
