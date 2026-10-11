import SwiftUI

struct StatusRow: View {
  struct ActionButton {
    let title: String
    let perform: () -> Void
  }

  let isPassing: Bool
  let title: String
  let detail: String
  var action: ActionButton?

  var body: some View {
    HStack(alignment: .top, spacing: Metrics.Spacing.comfortable) {
      Image(systemName: isPassing ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        .foregroundStyle(isPassing ? Color.green : Color.orange)
        .frame(width: Metrics.Size.statusIcon)
        .accessibilityLabel(isPassing ? "Passed" : "Needs attention")
      VStack(alignment: .leading, spacing: Metrics.Spacing.regular) {
        VStack(alignment: .leading, spacing: Metrics.Spacing.hairline) {
          Text(title)
          CaptionText(detail)
        }
        if let action {
          Button(action.title, action: action.perform)
        }
      }
      Spacer(minLength: 0)
    }
  }
}
