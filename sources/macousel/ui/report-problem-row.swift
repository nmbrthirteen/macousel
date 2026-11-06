import SwiftUI

struct ReportProblemRow: View {
  let diagnostics: DiagnosticsAction

  var body: some View {
    LabeledContent {
      Button("Save diagnostics") {
        Task(priority: .utility) { await diagnostics.save() }
      }
      .disabled(diagnostics.isSaving)
    } label: {
      RowLabel(
        title: "Report a problem",
        detail: "Saves a diagnostics file to your Desktop to attach to a GitHub issue.")
    }
    if let message = diagnostics.failureMessage {
      ErrorText(message)
    }
  }
}
