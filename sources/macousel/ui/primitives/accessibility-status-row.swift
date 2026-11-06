import SwiftUI
import WindowSystem

struct AccessibilityStatusRow: View {
  let status: AccessibilityStatus
  let grant: StatusRow.ActionButton

  var body: some View {
    StatusRow(
      isPassing: status.isGranted,
      title: status.isGranted ? "Accessibility access granted" : "Accessibility access needed",
      detail: "macOS only lets an app move other apps' windows through the Accessibility API.",
      action: status.isGranted ? nil : grant
    )
    .pollsAccessibility(status)
    if !status.isGranted {
      LabeledContent {
        Button("Reset and ask again", action: resetAndAsk)
      } label: {
        RowLabel(
          title: "Already on in System Settings?",
          detail: "macOS ties the permission to this exact build, so each update needs it again.")
      }
    }
  }

  private func resetAndAsk() {
    Task {
      await AccessibilityPermission.resetGrant()
      AccessibilityGuide.shared.begin()
    }
  }
}
