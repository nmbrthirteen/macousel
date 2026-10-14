import SwiftUI
import WindowSystem

struct AccessibilityGrantLine: View {
  let status: AccessibilityStatus

  var body: some View {
    HStack(spacing: Metrics.Spacing.comfortable) {
      Label(
        status.isGranted ? "Access granted" : "Access needed",
        systemImage: status.isGranted ? "checkmark.circle.fill" : "lock.circle.fill"
      )
      .foregroundStyle(status.isGranted ? Color.green : Color.secondary)
      .contentTransition(.symbolEffect(.replace))
      Spacer(minLength: 0)
      if !status.isGranted {
        Button("Open System Settings", action: AccessibilityPermission.requestWithPrompt)
      }
    }
    .pollsAccessibility(status)
  }
}
