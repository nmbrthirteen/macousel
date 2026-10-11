import SwiftUI

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
  }
}
