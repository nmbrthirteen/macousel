import SwiftUI

struct OverviewPermissionNotice: View {
  let onAllow: () -> Void

  var body: some View {
    HStack(spacing: Metrics.Spacing.regular) {
      Text("Allow Screen Recording to see window previews")
        .foregroundStyle(.secondary)
      Button("Open System Settings", action: onAllow)
        .buttonStyle(.link)
    }
    .font(.overlay(.small))
    .padding(.bottom, Metrics.Overview.noticeInset)
  }
}
