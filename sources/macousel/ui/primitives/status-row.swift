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
    LabeledContent {
      if let action {
        Button(action.title, action: action.perform)
      }
    } label: {
      Label {
        RowLabel(title: title, detail: detail)
      } icon: {
        Image(systemName: isPassing ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
          .foregroundStyle(isPassing ? Color.green : Color.orange)
          .accessibilityLabel(isPassing ? "Passed" : "Needs attention")
      }
    }
  }
}
