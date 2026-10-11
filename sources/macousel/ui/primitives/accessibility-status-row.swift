import SwiftUI
import WindowSystem

struct AccessibilityStatusRow: View {
  let status: AccessibilityStatus
  let grant: StatusRow.ActionButton

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.comfortable) {
      StatusRow(
        isPassing: status.isGranted,
        title: status.isGranted ? "Accessibility access granted" : "Accessibility access needed",
        detail: "macOS only lets an app move other apps' windows through the Accessibility API.",
        action: status.isGranted ? nil : grant
      )
      if !status.isGranted {
        CaptionText(
          "Already on in System Settings? macOS ties the permission to this exact build, so each update needs it again."
        )
        Button("Reset and ask again", action: resetAndAsk)
      }
    }
    .pollsAccessibility(status)
  }

  private func resetAndAsk() {
    AccessibilityPermission.resetGrant()
    AccessibilityPermission.requestWithPrompt()
  }
}
