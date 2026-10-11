import Foundation

struct DiagnosticsSaver {
  let destination: URL
  let environment: DiagnosticsEnvironment
  let crashReports: CrashReportLister
  let logReader: any LogReading
  let now: () -> Date

  func fileName() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH.mm"
    return "Macousel diagnostics \(formatter.string(from: now())).txt"
  }

  func save(preferences: Preferences) async throws -> URL {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let preferencesJSON = String(decoding: try encoder.encode(preferences), as: UTF8.self)
    let report = DiagnosticsReport(
      environment: environment, preferencesJSON: preferencesJSON,
      crashReports: crashReports.names, log: await logText())
    let file = destination.appendingPathComponent(fileName())
    try report.text.write(to: file, atomically: true, encoding: .utf8)
    return file
  }

  private func logText() async -> String {
    do {
      return try await logReader.recentEntries()
    } catch let failure as SystemLogReader.Failure {
      return "The log could not be read (exit status \(failure.status)). \(failure.output)"
    } catch {
      return "The log could not be read. \(error.localizedDescription)"
    }
  }
}
