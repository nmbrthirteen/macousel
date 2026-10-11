import AppKit
import os

@Observable
final class DiagnosticsAction {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "diagnostics")

  private(set) var failureMessage: String?
  private(set) var isSaving = false
  @ObservationIgnored private let store: PreferencesStore
  @ObservationIgnored private let engineReport: () -> EngineReport?

  init(store: PreferencesStore, engineReport: @escaping () -> EngineReport?) {
    self.store = store
    self.engineReport = engineReport
  }

  func save() async {
    guard !isSaving,
      let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    else { return }
    isSaving = true
    defer { isSaving = false }
    let saver = DiagnosticsSaver(
      destination: desktop, environment: .current(),
      crashReports: CrashReportLister(
        directory: FileManager.default.homeDirectoryForCurrentUser
          .appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)),
      logReader: SystemLogReader(), now: { Date() })
    do {
      let file = try await saver.save(preferences: store.preferences, engine: engineReport())
      failureMessage = nil
      NSWorkspace.shared.activateFileViewerSelecting([file])
    } catch {
      Self.logger.error("Diagnostics failed: \(error.localizedDescription, privacy: .public)")
      failureMessage = "Could not save diagnostics to the Desktop. Check that you can write there."
    }
  }
}
