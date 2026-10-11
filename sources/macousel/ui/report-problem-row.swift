import SwiftUI

struct ReportProblemRow: View {
  let diagnostics: DiagnosticsAction

  var body: some View {
    CaptionedRow(caption: "Saves a diagnostics file to your Desktop to attach to a GitHub issue.") {
      Button("Report a problem") {
        Task(priority: .utility) { await diagnostics.save() }
      }
      .disabled(diagnostics.isSaving)
    }
    if let message = diagnostics.failureMessage {
      ErrorText(message)
    }
  }
}
