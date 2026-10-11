import SwiftUI

struct ActivityRow: View {
  let text: String
  let isWorking: Bool

  var body: some View {
    HStack(spacing: Metrics.Spacing.regular) {
      if isWorking {
        ProgressView()
          .controlSize(.small)
      }
      Text(text)
    }
  }
}
