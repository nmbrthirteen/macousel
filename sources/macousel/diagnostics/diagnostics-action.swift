import AppKit
import WindowSystem
import os

@Observable
final class DiagnosticsAction {
  private static let logger = Logger(subsystem: Log.subsystem, category: "diagnostics")

  private(set) var failureMessage: String?
  private(set) var isSaving = false
  @ObservationIgnored private let store: PreferencesStore
  @ObservationIgnored private let engineReport: () async -> EngineReport?

  init(store: PreferencesStore, engineReport: @escaping () async -> EngineReport?) {
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
      let file = try await saver.save(preferences: store.preferences, engine: await engineReport())
      failureMessage = nil
      NSWorkspace.shared.activateFileViewerSelecting([file])
    } catch {
      Self.logger.error("Diagnostics failed: \(error.localizedDescription, privacy: .public)")
      failureMessage = "Could not save diagnostics to the Desktop. Check that you can write there."
    }
  }
}
